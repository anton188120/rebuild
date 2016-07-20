$default_tag="initial"

def NormalizeEnvName(env)
  name, tag = env.split(/:/)
  if tag.to_s.empty?
    tag=$default_tag
  end
  fullname=name + ":" + tag

  return name, tag, fullname
end

def EnvironmentIsModified?(fullname)
  return %x(rbld status).include? fullname
end

Given(/^existing environment ([a-zA-Z\d\:\-\_]+)$/) do |env|
  name, tag, fullname = NormalizeEnvName(env)
  env_list = %x(rbld list)

  unless env_list.include? fullname

    unless env_list.include? name + ":" + $default_tag
      %x(rbld create --base fedora:20 #{name})
      raise("Test environment #{name} creation failed") unless $?.success?
    end

    unless tag == $default_tag
      %x(rbld modify #{name} -- echo "Modifying the environment")
      raise("Test environment #{name} modification failed") unless $?.success?

      %x(rbld commit --tag #{tag} #{name})
      raise("Test environment #{fullname} commit failed") unless $?.success?
    end

  end

  if EnvironmentIsModified? fullname
    %x(rbld checkout #{fullname})
    raise("Test environment #{fullname} checkout failed") unless $?.success?
  end
end

Given(/^non-existing environment ([a-zA-Z\d\:\-\_]+)$/) do |env|
  name, tag, fullname = NormalizeEnvName(env)
  env_list = %x(rbld list)

  if env_list.include? fullname
    %x(rbld rm #{fullname})
    raise("Test environment #{fullname} deletion failed") unless $?.success?
  end
end

Then(/^environment ([a-zA-Z\d\:\-\_]+) should be marked as modified$/) do |env|
  name, tag, fullname = NormalizeEnvName(env)
  expect(EnvironmentIsModified?(fullname)).to be true
end

Then(/^environment ([a-zA-Z\d\:\-\_]+) should not be marked as modified$/) do |env|
  name, tag, fullname = NormalizeEnvName(env)
  expect(EnvironmentIsModified?(fullname)).to be false
end

Then(/^environment ([a-zA-Z\d\:\-\_]+) should exist$/) do |env|
  name, tag, fullname = NormalizeEnvName(env)
  steps %Q{
    When I successfully run `rbld list`
    Then the output should contain:
      """
      #{fullname}
      """
  }
end

Then(/^environment ([a-zA-Z\d\:\-\_]+) should not exist$/) do |env|
  name, tag, fullname = NormalizeEnvName(env)
  steps %Q{
    When I successfully run `rbld list`
    Then the output should not contain:
      """
      #{fullname}
      """
  }
end

Given(/^environment ([a-zA-Z\d\:\-\_]+) is modified$/) do |env|
  name, tag, fullname = NormalizeEnvName(env)
  unless EnvironmentIsModified?(fullname)
    %x(rbld modify #{fullname} -- echo Modifying...)
    raise("Test environment #{fullname} modification failed") unless $?.success?
  end
end

Given(/^environment ([a-zA-Z\d\:\-\_]+) is not modified$/) do |env|
  name, tag, fullname = NormalizeEnvName(env)
  if EnvironmentIsModified?(fullname)
    %x(rbld checkout #{fullname})
    raise("Test environment #{fullname} checkout failed") unless $?.success?
  end
end

Then(/^the output should be empty$/) do
  steps %Q{
    Then the output should contain exactly:
      """
      """
  }
end