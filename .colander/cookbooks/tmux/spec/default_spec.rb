require 'spec_helper'

describe 'tmux::default' do
  before { Fauxhai.mock(platform: 'ubuntu', version: '12.04') }
  let(:runner) { ChefSpec::ChefRunner.new.converge('tmux::default') }

  it 'should install the tmux package' do
    runner.should install_package 'tmux'
  end

  it 'should drop the tmux.conf template' do
    runner.should create_file_with_content '/etc/tmux.conf', 'set -g prefix C-a'
  end
end
