class Section::ShowService
  def initialize(context:)
    @context = context
  end

  def call
    [manual, section]
  end

private

  attr_reader :context

  def section
    @section ||= manual.sections.find { |s| s.id == section_id }
  end

  def manual
    @manual ||= Manual.find(manual_id, context.current_user)
  end

  def section_id
    context.params.fetch("id")
  end

  def manual_id
    context.params.fetch("manual_id")
  end
end