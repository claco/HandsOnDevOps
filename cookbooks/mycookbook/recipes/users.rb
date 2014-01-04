#
# Cookbook Name:: mycookbook
# Recipe:: users
#
# Copyright 2014, Christopher H. Laco
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

user "build" do
  home "/home/build"
  shell "/bin/bash"
  password "$6$ECIy/pVovVQ6qja$A0owsw1LKsPPUQe2CKi.5IfAWuLGvyj3IgiRJfFxG3/MrmYTiAOPRE0qaBVv/lBgmSfI27T.Tg2EzrC7A72qI/"
  supports :manage_home => true
end

directory "/home/build/.ssh" do
  owner "build"
  group "build"
  mode "0700"
end

cookbook_file "/home/build/.ssh/authorized_keys" do
  source "ssh/id_rsa.pub"
  owner "build"
  group "build"
  mode "0600"
end

template "/etc/sudoers.d/build" do
  source "sudo/user.erb"
  owner "root"
  group "root"
  mode "0440"
  variables :username => "build"
end
