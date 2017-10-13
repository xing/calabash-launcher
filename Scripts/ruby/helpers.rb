# Evaluate a loop when new command appear in temp file.
# Used to send Calabash command to an existing calabash console session.
def eval_loop
    loop do
        begin
            ap (eval gets), options = { plain: false, color: { array: :yellow } }
        rescue Exception => e
            puts 'RESCUED!'
            puts e
        end
    end
end

# Returns elements addresses that are situated under (x, y)
# Returns address for Calabash as well as whole element hash in order to compare it with founded elements
def get_element_string_addresses(x, y)
    x = x.to_f
    y = y.to_f
    all_elements = query '*'
    elements = []
    query_pair = {}

    all_elements.each do | element |
        all_rects = element['rect']
        coordinates = [all_rects['x'], all_rects['y'], all_rects['x'] + all_rects['width'], all_rects['y'] + all_rects['height']]
        next unless x.between?(coordinates[0], coordinates[2]) && y.between?(coordinates[1], coordinates[3])

        if element['class'].start_with?('_')
            elements << "view:'#{element['class']}'"
            query_pair.merge!("view:'#{element['class']}'": element)
            next
        end

        unless element['id'].nil? || element['id'] == ''
            elements.unshift("#{element['class']} id:'#{element['id']}'")
            query_pair.merge!("#{element['class']} id:'#{element['id']}'": element)
            next
        end

        unless element['label'].nil? || element['label'] == ''
            elements.unshift("#{element['class']} marked:'#{element['label']}'")
            query_pair.merge!("#{element['class']} marked:'#{element['label']}'": element)
            next
        end

        unless element['text'].nil? || element['text'] == ''
            elements.unshift("#{element['class']} marked:'#{element['text']}'")
            query_pair.merge!("#{element['class']} marked:'#{element['text']}'": element)
            next
        end

        elements << element['class']
        query_pair.merge!("#{element['class']}": element)
    end

  return elements, query_pair
end

# Gets last childs from the element hierarchy assuming that it is the element that user wanted to find in the first place
def get_last_child(giant_array, elements)
    last_childs = []

    for i in 0..elements.size - 1 do
        element_indentation = find_element_indentation(elements[i], giant_array, 0)
        if element_indentation == nil
            File.open('/tmp/element_array.txt', 'w+') do |f|
                elements.each { |element| f.puts("\"#{element}\"") }
                raise "Wasn't able to build a correct hierarchy"
            end
        end
        all_child_elements_result = find_element_childs(element_indentation, giant_array)
        if all_child_elements_result == []
            last_childs << elements[i]
            break
        end
        child_size = all_child_elements_result.size
        all_child_elements_result -= elements
        next if all_child_elements_result.size != child_size
        last_childs << elements[i]
    end
    last_childs.uniq
end

def get_elements_by_offset(x, y)
    element_array_file = "element_array.txt"
    FileUtils.rm(element_array_file) if File.file?(element_array_file)

    elements, query_pair = get_element_string_addresses(x, y)
    elements = elements.uniq

    hash_tree = JSON.parse(http(method: :get, path: 'dump'))
    giant_array = dump_json_data_over hash_tree


    last_childs = get_last_child(giant_array, elements)

    all_parent_elements_result = []
    all_parent_elements_middle = []
    check_for_duplicate = []
    skip_match = 0

    for j in 0..last_childs.size - 1 do
        redo_the_loop = false
        element_indentation = find_element_indentation(last_childs[j], giant_array, skip_match)
        if element_indentation == nil
            File.open('/tmp/element_array.txt', 'w+') do |f|
                elements.each { |element| f.puts("\"#{element}\"") }
                raise "Wasn't able to build a correct hierarchy"
            end
        end
        new_result = find_element_parents(element_indentation, giant_array)

        for g in 0..new_result.size - 1 do

            relation = if g == 0
                           'child'
                       else
                           'descendant'
                       end

            if query("#{new_result[g]} #{relation} #{last_childs[j]}").include?(query_pair[last_childs[j].to_sym])

                redo_the_loop = false
            else
                skip_match += 1
                redo_the_loop = true
                break
            end
        end

        if redo_the_loop
            redo
        else
            skip_match = 0
        end

        new_element = new_result.clone
        check_for_duplicate << new_element.unshift(last_childs[j])

        all_parent_elements_result << ['separator']
        all_parent_elements_middle << new_result[0]
        all_parent_elements_result << new_result
    end

    nn = []
    for l in 0..check_for_duplicate.size - 1 do
        for k in 0..check_for_duplicate.size - 1 do
            next if l == k
            nn << l if check_for_duplicate[l] - check_for_duplicate[k] == []
        end
    end

    nn = nn.uniq
    nn = nn.sort.reverse

    unless nn.empty?
        for i in 0..nn.size - 1 do
            last_childs.delete_at(nn[i])
            all_parent_elements_middle.delete_at(nn[i])
            all_parent_elements_result.delete_at(nn[i] + nn[i] + 1)
            all_parent_elements_result.delete_at(nn[i] + nn[i])
        end
    end

    File.open('/tmp/element_array.txt', 'w+') do |f|
        last_childs.each { |element| f.puts("\"#{element}\"") }
        f.puts '=========='
        all_parent_elements_result.each { |element| element.each { |array_element| f.puts("\"#{array_element}\"") } }
    end
end

def flash_utf(qu)
    qu = qu.to_s.encode('UTF-8', {
        :invalid => :replace,
        :undef   => :replace,
        :replace => '?'
    })
    flash qu
end

def screenshot_with_no_output
    scr = screenshot(options = { prefix: '/tmp/' })
end

def screenshot_handling_no_loop
    scr = 'screenshot_*'
    begin
        system "rm /tmp/#{scr} 2> /dev/null"
    rescue Exception
    end
    begin
        scr = screenshot_with_no_output
    rescue Exception => e
        return e.message
    end

    `mv #{scr} /tmp/screenshot_0.png`
    nil
end

@filename = '/tmp/calabash_pipe'

unless File.exist?(@filename)
    File.mkfifo(@filename)
    File.chmod(666, @filename)
end

@file = File.open(@filename, 'r')
@writer = File.open(@filename, 'w')

def gets
    str = ''
    str << (r = @file.read(1)) until r == "\n"
    str
end

$output_psc = []
ElementStructure = Struct.new(:indentation, :address)

def dump_json_data_over(json_data)
    $output_psc = []
    json_data['children'].each { |child| write_child_over(child) }
    $output_psc
end

def write_child_over(data, indentation = 0)
    render_over(data, indentation)
    data['children'].each do |child|
        write_child_over(child, indentation + 1)
    end
end

def render_over(data, indentation)
    if visible_over?(data)
        type = data['type']
        str_id = data['id']
        str_label = data['label']
        str_text = data['value']
        skip = false
        element_full_name = ElementStructure.new(indentation, type.to_s)

        if !data['id'].nil?
            element_full_name.address = "#{element_full_name.address} id:'#{str_id}'"
            skip = true
        elsif !data['label'].nil?
            element_full_name.address = "#{element_full_name.address} marked:'#{str_label}'" unless skip
            skip = true
        elsif !data['value'].nil?
            element_full_name.address = "#{element_full_name.address} text:'#{str_text}'" unless skip
        end

        $output_psc << element_full_name
    end
end

def visible_over?(data)
    (data['visible'] == 1) || data['children'].map { |child| visible_over?(child) }.any?
end

def find_element_indentation(name, output_array, skip_match)

    skipped = 0
    found = false
    for i in 0..output_array.size - 1
        next unless output_array[i].address == name
        output_array[i].indentation
        if skipped == skip_match
            found = true
            break
        end
        skipped += 1
    end
    unless found
        return nil
    end
    [output_array[i].indentation, i]
end

def find_element_parents(element_indentation, output_array)
    all_parents = []

    element_indentation_current, element_index_current = element_indentation

    for i in element_index_current.downto(0)
        if output_array[i].indentation == element_indentation_current - 1

          if output_array[i].address.start_with?('_')
            output_array[i].address = "view:'#{output_array[i].address}'"
          end

            all_parents << output_array[i].address
            element_indentation_current -= 1
        end
        break if element_indentation_current == 0
    end
    all_parents
end

def find_element_childs(element_indentation, output_array)
    all_childs = []
    element_indentation_current = element_indentation.first
    element_index_current = element_indentation.last
    for _ in element_index_current..output_array.size - 1
        for i in element_index_current..output_array.size - 1
            break if output_array[i].indentation == element_indentation_current - 1
            if output_array[i].indentation == element_indentation_current + 1

              if output_array[i].address.start_with?('_')
                output_array[i].address = "view:'#{output_array[i].address}'"
              end

                all_childs << output_array[i].address
            end
        end
        element_indentation_current += 1
    end
    all_childs.uniq
end

def get_elements_from_screen(kind = nil, filename = nil)
    output = filename ? File.open(filename, 'w') : $stdout

    kinds = [:id, :text, nil]
    unless kinds.include?(kind)
        raise ArgumentError,
              "'#{kind}' is not one of '#{kinds}'"
    end

    acc_method = case kind
                     when :text
                         elements = text_marks(print: true, return: true)
                         'text:'
                     when :id
                         elements = accessibility_marks(:id, print: true, return: true)
                         'id:'
                     else
                         elements = accessibility_marks(:label, print: true, return: true)
                         'marked:'
                 end

    classes = elements.collect { |x| x[0] }
    labels = elements.collect { |x| x[1] }

    n = classes.size

    for i in 0..n - 1 do
        postfix = ''
        text_clone = labels[i].clone
        string = "#{classes[i]} #{acc_method}'#{text_clone}'"

        output.puts "\n"
        output.puts "def #{text_clone}"
        output.puts "  \"#{string}\""
        output.puts 'end'
    end
    output.close if filename
end

def search_string_in_file(contents_array, string)
    n = contents_array.size
    
    string.gsub!(' ￼', '')

    for array_index in 0..n - 1 do
        next unless contents_array[array_index]
        if contents_array[array_index].include? '='
            text = contents_array[array_index].strip.split('"')[3]
        elsif contents_array[array_index].include? ':'
            text = contents_array[array_index].strip.split(': ')[1]
        end

        next unless text
        if text == string
            break
        else
            array_index = nil
        end
    end
    array_index
end

def get_uniq_elements(x, y, element, child, sibling, by_index)
    x = x.to_f
    y = y.to_f

    `rm element_array.txt`
    all_elements = query '*'
    all_rects = []
    coordinates = []
    elements = []
    all_child_elements_result = []
    query_pair = {}

    for i in 0..all_elements.size - 1 do
        all_rects << all_elements[i]['rect']
        coordinates << [all_rects[i]['x'], all_rects[i]['y'], all_rects[i]['x'] + all_rects[i]['width'], all_rects[i]['y'] + all_rects[i]['height']]
        next unless x.between?(coordinates[i][0], coordinates[i][2]) && y.between?(coordinates[i][1], coordinates[i][3])

        unless all_elements[i]['id'].nil? || all_elements[i]['id'] == ''
            elements.unshift("#{all_elements[i]['class']} id:'#{all_elements[i]['id']}'")
            query_pair.merge!("#{all_elements[i]['class']} id:'#{all_elements[i]['id']}'": all_elements[i])
            next
        end

        unless all_elements[i]['label'].nil? || all_elements[i]['label'] == ''
            elements.unshift("#{all_elements[i]['class']} marked:'#{all_elements[i]['label']}'")
            query_pair.merge!("#{all_elements[i]['class']} marked:'#{all_elements[i]['label']}'": all_elements[i])
            next
        end

        unless all_elements[i]['text'].nil? || all_elements[i]['text'] == ''
            elements.unshift("#{all_elements[i]['class']} marked:'#{all_elements[i]['text']}'")
            query_pair.merge!("#{all_elements[i]['class']} marked:'#{all_elements[i]['text']}'": all_elements[i])
            next
        end

        if all_elements[i]['class'].start_with?('_')
          elements << "view:'#{all_elements[i]['class']}'"
          query_pair.merge!("view:'#{all_elements[i]['class']}'": all_elements[i])
          next
        end

        elements << all_elements[i]['class']
        query_pair.merge!("#{all_elements[i]['class']}": all_elements[i])

    end

    elements = elements.uniq
    hash_tree = JSON.parse(http(method: :get, path: 'dump'))
    giant_array = dump_json_data_over hash_tree

    all_parent_elements_result = []

    skip_match = 0
    redo_the_loop = false

    for j in 0..0 do
        redo_the_loop = false
        element_indentation = find_element_indentation(element, giant_array, skip_match)
        new_result = []
        new_result = find_element_parents(element_indentation, giant_array)

        for g in 0..new_result.size - 1 do

            relation = if g == 0
                           'child'
                       else
                           'descendant'
                       end

            if query("#{new_result[g]} #{relation} #{element}").include?(query_pair[element.to_sym])

                redo_the_loop = false
            else
                skip_match += 1
                redo_the_loop = true
                break
            end
        end

        if redo_the_loop
            redo
        else
            skip_match = 0
        end

        all_parent_elements_result << new_result
    end

    all_parent_elements_result = all_parent_elements_result.uniq
    unique_elements_array = []

    if child.to_s == '1'
    for k in 0..all_parent_elements_result.first.size - 1 do
        address_to_try = if k == 0
                             "#{all_parent_elements_result.first[k]} child #{element}"
                         else
                             "#{all_parent_elements_result.first[k]} descendant #{element}"
                         end
        query_address_to_try = query(address_to_try)

        if query_address_to_try.include?(query_pair[element.to_sym]) && query_address_to_try.size == 1
            unique_elements_array << address_to_try
        end
    end
    end

    if sibling.to_s == '1'
    found = 0

    for k in 0..all_parent_elements_result.first.size - 1 do

        hierarchy_element = if k == 0
                                'child'
                            else
                                'descendant'
                            end

        new_query = query("#{all_parent_elements_result.first[k]} sibling *")

        for d in 0..new_query.size - 1 do
            sibling = nil

            if !new_query[d]['label'].nil?
                sibling = "#{new_query[d]['class']} marked:'#{new_query[d]['label']}'"
            elsif !new_query[d]['text'].nil?
                sibling = "#{new_query[d]['class']} marked:'#{new_query[d]['label']}'"
            elsif !new_query[d]['id'].nil?
                sibling = "#{new_query[d]['class']} id:'#{new_query[d]['id']}'"
            else
                sibling = "#{new_query[d]['class']}"
            end

            next unless sibling
            sibling_element = "#{sibling} sibling #{all_parent_elements_result.first[k]} #{hierarchy_element} #{element}"
            query_sibling_element = query(sibling_element)
            break if sibling_element.empty?

            if query_sibling_element.include?(query_pair[element.to_sym]) && query_sibling_element.size == 1
                unique_elements_array << sibling_element
                found += 1
                break
            end
        end

        break if found == 3

    end
    end

    maxdepth_ = 10

    if by_index.to_s == '1'

        for k in 0..all_parent_elements_result.first.size - 1 do

            hierarchy_element = if k == 0
                                    'child'
                                else
                                    'descendant'
                                end

            address_to_try_parent = all_parent_elements_result.first[k]

            query_address_to_try_parent = query(address_to_try_parent)

            for t in 0..query_address_to_try_parent.size - 1 do
                break if t == maxdepth_
                parent_index_query = query("#{address_to_try_parent} index:#{t} #{hierarchy_element} #{element}")
                next unless (parent_index_query.first == query_pair[element.to_sym]) && (parent_index_query.size == 1)
                unique_elements_array << "#{address_to_try_parent} index:#{t} #{hierarchy_element} #{element}"
                maxdepth_ = t
                break
            end
        end

        for k in 0..all_parent_elements_result.first.size - 1 do
            address_to_try = if k == 0
                                 "#{all_parent_elements_result.first[k]} child #{element}"
                             else
                                 "#{all_parent_elements_result.first[k]} descendant #{element}"
                             end

            query_address_to_try = query(address_to_try)

            for t in 0..query_address_to_try.size - 1 do
                break if t == maxdepth_
                child_index_query = query("#{address_to_try} index:#{t}")
                next unless (child_index_query.first == query_pair[element.to_sym]) && (child_index_query.size == 1)
                unique_elements_array << "#{address_to_try} index:#{t}"
                maxdepth_ = t
                break
            end
        end
    end

    File.open('/tmp/uniq_elements.txt', 'w+') do |f|
        if unique_elements_array.empty?
            f.puts("Can't find any matches for your request. Please try other option.")
        else
            unique_elements_array.each { |element| f.puts("\"#{element}\"") }
        end
    end
end
        
def healthcheck
running = true
begin
    launcher.ping_app
    rescue Errno::ECONNREFUSED => _
    running = false
end

    unless launcher.automator.nil?
        running = false unless launcher.automator.client.running?
    else
        running = false
    end
    
    File.open('/tmp/is_running.txt', 'w+') do |f|
    f.puts running
    end
    
end


