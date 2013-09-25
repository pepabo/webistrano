require 'test_helper'

class DeploymentsControllerTest < ActionController::TestCase

  def setup
    @project = FactoryGirl.create(:project, :name => 'Project X')
    @stage = FactoryGirl.create(:stage, :name => 'Prod', :project => @project)
    @role = FactoryGirl.create(:role, :name => 'web', :stage => @stage)
    @deployment = FactoryGirl.create(:deployment, :task => 'deploy:setup', :stage => @stage)

    @user = login
  end

  test "should_get_new_if_deployment_possible" do
    assert @stage.deployment_possible?
    get :new, :project_id => @project.id, :stage_id => @stage.id
    assert_response :success
  end

  test "should_not_get_new_if_deployment_not_possible" do
    @stage.roles.clear
    assert !@stage.deployment_possible?

    get :new, :project_id => @project.id, :stage_id => @stage.id
    assert_response :redirect
  end

  test "should_create_deployment_if_deployment_possbile" do
    Deployment.delete_all
    assert @stage.deployment_possible?

    host_ids = @stage.hosts.map { |h| h.id.to_i }

    post :create, :deployment => { :host_ids => host_ids, :task => 'deploy:default', :description => 'update to newest' }, :project_id => @project.id, :stage_id => @stage.id
    assert_equal 1, Deployment.count
    assert_equal @user, Deployment.find(:all).last.user

    assert_redirected_to project_stage_deployment_path(@project, @stage, assigns(:deployment))
  end

  test "should_not_create_deployment_if_deployment_not_possbile" do
    @stage.roles.clear
    assert !@stage.deployment_possible?

    old_count = Deployment.count
    post :create, :deployment => { :task => 'deploy:default', :description => 'update to newest' }, :project_id => @project.id, :stage_id => @stage.id
    assert_equal old_count, Deployment.count

    assert_redirected_to project_stage_path(@project, @stage)
  end

  test "should_show_deployment" do
    get :show, :id => @deployment.id, :project_id => @project.id, :stage_id => @stage.id
    assert_response :success
  end

  test "given_task_name" do
    assert @stage.deployment_possible?

    get :new, :task => 'deploy:default' , :project_id => @project.id, :stage_id => @stage.id
    assert_response :success
    assert_equal 'deploy:default', assigns(:deployment).task
  end

  test "prompt_before_deploy" do
    Deployment.delete_all
    assert @stage.deployment_possible?

    # add a config value that wants a promp
    @stage.configuration_parameters.build(:name => 'password', :prompt_on_deploy => 1).save!

    get :new, :task => 'deploy:default' , :project_id => @project.id, :stage_id => @stage.id
    assert_response :success

    # check that we get asked for the password
    assert_match /password/, @response.body

    host_ids = @stage.hosts.map { |h| h.id.to_i }

    # test that we need to enter this parameters
    post :create, :deployment => { :host_ids => host_ids, :task => 'deploy:default', :description => 'update to newest', :prompt_config => {} }, :project_id => @project.id, :stage_id => @stage.id
    assert_response :redirect
    assert_equal 0, Deployment.count

    # now give the missing config
    post :create, :deployment => { :host_ids => host_ids, :task => 'deploy:default', :description => 'update to newest', :prompt_config => {:password => 'abc'} }, :project_id => @project.id, :stage_id => @stage.id
    assert_response :redirect
    assert_equal 1, Deployment.count
  end

  test "excluded_hosts" do
    Deployment.delete_all
    host_down = FactoryGirl.create(:host)
    down_role = FactoryGirl.create(:role, :stage => @stage, :name => 'foo', :host => host_down)
    host_ids = @stage.hosts.map { |h| h.id.to_i } - [host_down.id]

    assert_equal 2, @stage.roles.count

    post :create, :deployment => { :host_ids => host_ids, :task => 'deploy:default', :description => 'update to newest', :prompt_config => {} }, :project_id => @project.id, :stage_id => @stage.id

    assert_equal 1, Deployment.count
    deployment = Deployment.find(:first)
    assert_equal [host_down], deployment.excluded_hosts
    assert_equal [@role], deployment.deploy_to_roles
  end

  test "latest_deployment" do
    Deployment.delete_all
    host_down = FactoryGirl.create(:host)
    down_role = FactoryGirl.create(:role, :stage => @stage, :name => 'foo', :host => host_down)
    host_ids = @stage.hosts.map { |h| h.id.to_i } - [host_down.id]

    post :create, :deployment => { :host_ids => host_ids, :task => 'deploy:default', :description => 'update to newest', :prompt_config => {} }, :project_id => @project.id, :stage_id => @stage.id
    get :latest, :project_id => @project.id, :stage_id => @stage.id
    assert_response :redirect
    assert_equal "deploy:default", assigns(:deployment).task
  end

  test "latest_with_no_deployment" do
    Deployment.delete_all
    host_down = FactoryGirl.create(:host)
    down_role = FactoryGirl.create(:role, :stage => @stage, :name => 'foo', :host => host_down)
    get :latest, :project_id => @project.id, :stage_id => @stage.id, :format => "xml"
    assert_response 404
  end

  test "cancel" do
    @deployment.pid = 123
    @deployment.save!
    assert @deployment.running?
    assert @deployment.cancelling_possible?, @deployment.inspect

    Process.expects(:kill).returns(true).times(2)

    post :cancel, :project_id => @project.id, :stage_id => @stage.id, :id => @deployment.id
    assert_response :redirect
    assert_redirected_to project_stage_deployment_path(@project, @stage, @deployment)
    @deployment.reload
    assert @deployment.canceled?, flash[:error].to_s
  end

end
