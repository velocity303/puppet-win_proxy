require 'spec_helper'
describe 'win_proxy' do

  context 'with defaults for all parameters' do
    it { should contain_class('win_proxy') }
  end
end
