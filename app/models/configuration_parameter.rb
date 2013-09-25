class ConfigurationParameter < ActiveRecord::Base
  attr_accessible :name, :value, :prompt_on_deploy, :project_id
  
  validates :name, :presence => true
  validates :prompt_on_deploy, :inclusion => {:in => 0..1}
  validate :custom_validations
  
  before_validation :empty_value_if_deploy_is_set
  
  
  def prompt?
    self.prompt_on_deploy == 1
  end
  
  def empty_value_if_deploy_is_set
    self.value = nil if self.prompt?
  end
  
  def prompt_status_in_html
    if self.prompt?
      "<span class='configuration_prompt'>prompt</span>"
    else
      ''
    end
  end

private

  def custom_validations
    if self.prompt? and self.value.present?
      self.errors.add('value', 'must be empty if prompt on deploy is set')
    end

    if self.name.present? and self.name.strip.starts_with?(":")
      self.errors.add('name', 'can\'t contain a colon')
    end
  end

end
