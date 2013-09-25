module ProjectsHelper
  def project_clone_form_path(project)
    "#{new_project_path}?clone=#{project.id}"
  end

  def project_clone_path(project)
    "#{projects_path}?clone=#{project.id}"
  end
end
