require 'test_helper'

class StageTest < ActiveSupport::TestCase
  
  def setup
    Stage.delete_all
    @project = Project.create!(:name => 'Project 1', :template => 'rails')
  end

  test "creation_and_validation" do
    assert_equal 0, Stage.count
    
    s = Stage.new(:name => "Beta")
    
    # project is missing
    assert !s.valid?
    assert_not_empty s.errors['project']
    
  end
  
  test "validation" do
    s = Stage.new(:name => "Beta")
    
    # project is missing
    assert !s.valid?
    assert_not_empty s.errors['project']
    
    # make it pass
    s.project = @project
    assert s.save
    
    # try to create another project with the same name
    s = Stage.new(:name => "Beta")
    s.project = @project
    assert !s.valid?
    assert_not_empty s.errors["name"]
    
    # try to create a stage with a name that is too long
    name = "x" * 251
    s = Stage.new(:name => name)
    s.project = @project
    assert !s.valid?
    assert_not_empty s.errors["name"]

    # make it pass
    s.name = name.chop
    assert s.save
  end

  test "deployment_possible_roles" do
    project = FactoryGirl.create(:project, :template => 'rails')
    stage = FactoryGirl.create(:stage, :project => project)
    assert stage.roles.blank?
    
    # no roles, no deployment
    assert !stage.deployment_possible?
    assert_not_nil stage.deployment_problems[:roles]
    
    role = FactoryGirl.create(:role, :stage => stage)
    stage = Stage.find(stage.id) # stage.reload would not clear attr_accessor
    
    assert stage.deployment_possible?
    assert_nil stage.deployment_problems[:roles]
  end
  
  test "deployment_possible_vars" do
    project = FactoryGirl.create(:project, :template => 'rails')
    stage = FactoryGirl.create(:stage, :project => project)
    role = FactoryGirl.create(:role, :stage => stage)

    assert_not_nil stage.effective_configuration(:repository)
    assert_not_nil stage.effective_configuration(:application)
    
    # roles and config present => go
    assert stage.deployment_possible?
    
    # remove a config
    stage.configuration_parameters.find_by_name('repository').destroy rescue nil
    project.configuration_parameters.find_by_name('repository').destroy rescue nil
    
    stage = Stage.find(stage.id) # stage.reload would not clear attr_accessor
    
    assert_nil stage.effective_configuration(:repository)
    assert_not_nil stage.effective_configuration(:application)
    
    assert !stage.deployment_possible?
    assert_not_nil stage.deployment_problems[:repository]
    assert_nil stage.deployment_problems[:application]
    
    # add it again
    config = stage.configuration_parameters.build(:name => 'repository', :value => 'svn://bla.com/trunk')
    config.save!
    stage = Stage.find(stage.id) # stage.reload would not clear attr_accessor
    
    assert_not_nil stage.effective_configuration(:repository)
    assert_not_nil stage.effective_configuration(:application)
    assert stage.deployment_possible?
    assert stage.deployment_problems.blank?
    
    # remove the other one
    # remove a config
    stage.configuration_parameters.find_by_name('application').destroy rescue nil
    project.configuration_parameters.find_by_name('application').destroy rescue nil
    
    stage = Stage.find(stage.id) # stage.reload would not clear attr_accessor
    
    assert !stage.deployment_possible?
    assert_not_nil stage.effective_configuration(:repository)
    assert_nil stage.effective_configuration(:application)
    assert_nil stage.deployment_problems[:repository]
    assert_not_nil stage.deployment_problems[:application]
    
  end
  
  test "deployment_problems_can_be_called_with_explicit_check_with_deployment_possible" do
    stage = FactoryGirl.create(:stage)
    
    assert_nothing_raised{
      stage.deployment_problems[:application]
    }
  end
  
  test "configs_that_need_prompt" do
    ProjectConfiguration.delete_all
    @stage = FactoryGirl.create(:stage, :project => @project, :name => 'Production')
    @stage.reload
    
    # create two config entries, one that need a prompt
    @stage.configuration_parameters.build(:name => 'user', :value => 'deploy').save!
    @stage.configuration_parameters.build(:name => 'password', :prompt_on_deploy => 1).save!
    
    assert_equal 1, @stage.prompt_configurations.size
    assert_equal 1, @stage.non_prompt_configurations.size
  end
  
  test "alert_emails_format" do
    stage = FactoryGirl.create(:stage)
    assert_nil stage.alert_emails
    
    stage.alert_emails = "michael@jackson.com"    
    assert stage.valid?
    
    stage.alert_emails = "michael@example.com me@example.com"    
    assert stage.valid?
    assert_equal ['michael@example.com', 'me@example.com'], stage.emails
    
    stage.alert_emails = "michael@example.com me@example.com 123"    
    assert !stage.valid?
    
    stage.alert_emails = "michael@example.com You <me@example.com>"    
    assert !stage.valid?
    
    stage.alert_emails = "michael"    
    assert !stage.valid?
  end

  test "prepare_cloning" do
    original = FactoryGirl.create(:stage, :name => 'Some Stage', :alert_emails => 'foo@example.com')
    my = FactoryGirl.create(:stage, :alert_emails => 'baa@example.com')

    my.prepare_cloning(original)
    assert_equal "Clone of Some Stage", my.name
    assert_equal original.alert_emails, my.alert_emails
  end

  test "clone" do
    original = FactoryGirl.create(:stage, :name => 'Some Stage', :alert_emails => 'foo@example.com')
    3.times do |i|
      original.recipes << FactoryGirl.create(:recipe, :name => "#{i}-recipe")
    end
    3.times do |i|
      original.roles << FactoryGirl.create(:role, :name =>"#{i}-role")
    end
    3.times do |i|
      FactoryGirl.create(:stage_configuration, :stage => original, :name => "#{i}-stage-conf", :value => "value-#{i}")
    end
    new_stage = FactoryGirl.create(:stage)
    new_stage.clone(original)

    # check stage configuration
    assert_equal original.configuration_parameters.count, new_stage.configuration_parameters.count
    new_stage.configuration_parameters.each do |conf|
      orig = original.configuration_parameters.find_by_name(conf.name)
      assert_equal orig.name, conf.name
      assert_equal orig.value, conf.value
      assert_equal orig.prompt_on_deploy, conf.prompt_on_deploy
    end

    # check recipes
    assert_equal original.recipes.count, new_stage.recipes.count
    new_stage.recipes.each do |recipe|
      orig = original.recipes.find_by_name(recipe.name)
      assert_equal orig.name, recipe.name
      assert_equal orig.description, recipe.description
      assert_equal orig.body, recipe.body
    end

    # check roles
    assert_equal original.roles.count, new_stage.roles.count
    new_stage.roles.each do |role|
      orig = original.roles.find_by_name(role.name)
      assert_equal orig.name, role.name
      assert_equal orig.host_id, role.host_id
      assert_equal orig.primary, role.primary
      assert_equal orig.no_release, role.no_release
      assert_equal orig.ssh_port, role.ssh_port
      assert_equal orig.no_symlink, role.no_symlink
    end
  end


  test "recent_deployments" do
    stage = FactoryGirl.create(:stage)
    role = FactoryGirl.create(:role, :stage => stage)
    5.times do 
      deployment = FactoryGirl.create(:deployment, :stage => stage)
    end
    
    assert_equal 5, stage.deployments.count
    assert_equal 5, stage.deployments.recent.length
    assert_equal 2, stage.deployments.recent(2).length
  end
  
  test "webistrano_stage_name" do
    stage = FactoryGirl.create(:stage, :name => '&my_ Pro ject')
    assert_equal '_my__pro_ject', stage.webistrano_stage_name
  end
  
  test "handle_corrupt_recipes" do
    Open4.expects(:popen4)
    
    stage = FactoryGirl.create(:stage)
    
    # create a recipe with invalid code
    recipe = FactoryGirl.create(:recipe, :body => <<-'EOS'
      namescape do
        task :foo do
          run 'ls'
        end
      end
      EOS
    )
    
    assert_nothing_raised do
      stage.recipes << recipe
      stage.list_tasks
    end
  end
  
  test "locking_methods" do
    stage = FactoryGirl.create(:stage)
    assert !stage.locked?
    
    stage.lock
    
    assert stage.locked?, stage.inspect
    
    stage.unlock
    
    assert !stage.locked?
  end
  
  test "lock_info" do
    stage = FactoryGirl.create(:role, :name => 'app').stage
    deployment = FactoryGirl.create(:deployment, :stage => stage)
    stage.lock
    stage.lock_with(deployment)
    
    stage.reload
    assert_equal deployment, stage.locking_deployment
    
    stage.unlock
    assert_nil stage.locking_deployment
  end
  
  test "lock_with_can_not_be_called_without_being_locked" do
    stage = FactoryGirl.create(:role, :name => 'app').stage
    deployment = FactoryGirl.create(:deployment, :stage => stage)
    assert !stage.locked?
    
    assert_raise(ArgumentError) do
      stage.lock_with(deployment)
    end
  end
  
  test "locked_deployment_belongs_to_stage" do
    stage_1 = FactoryGirl.create(:role, :name => 'app').stage
    deployment_1 = FactoryGirl.create(:deployment, :stage => stage_1)
    stage_2 = FactoryGirl.create(:role, :name => 'app').stage
    deployment_2 = FactoryGirl.create(:deployment, :stage => stage_2)
    
    stage_1.lock
    assert_raise(ArgumentError) do
      stage_1.lock_with(deployment_2)
    end
  end
  
end
