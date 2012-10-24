#
# Cookbook Name:: tmux
# Recipe:: default
#
# Copyright 2012, Da Community
#
# All rights reserved - Do Not Redistribute
#
package 'tmux'

template '/etc/tmux.conf' do
  source 'tmux.conf.erb'
  mode '0644'
end
