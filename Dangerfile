not_declared_trivial = !github.pr_title.include?("trivial")

has_launcher_changes = !git.modified_files.grep(/Launcher/).empty?
has_core_changes = !git.modified_files.grep(/Core/).empty?
no_changelog_entry = !git.modified_files.include?("Changelog.md")

warn("The pull request is classed as Work in Progress") if github.pr_title.include? "WIP"
warn("Big pull request") if git.lines_of_code > 500

if (has_launcher_changes || has_core_changes) && not_declared_trivial
  warn("Any changes to library code should be reflected in the Changelog. Please consider adding a note there.")
end
