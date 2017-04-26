require "spec_helper"

RSpec.describe Manual::ListService do
  let(:user) { double(:user) }
  let(:context) { double(:context, current_user: user) }

  subject {
    Manual::ListService.new(
      context: context,
    )
  }

  it 'loads all manuals for the user' do
    expect(Manual).to receive(:all).with(user, anything)

    subject.call
  end

  it 'avoids loading manual associations' do
    expect(Manual).to receive(:all).with(anything, load_associations: false)

    subject.call
  end
end