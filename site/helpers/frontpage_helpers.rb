module FrontPageHelpers
  def what_we_do
    high_level_sectors_structure.sort_by {|s| -s[:budget]}.slice! 1, 5 || []
  end

  def what_we_achieve
    @cms_db['whatweachieve'].find({})
  end
end