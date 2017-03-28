class ManualPublishTaskAssociationMarshaller
  def initialize
    @decorator = ->(manual, attrs) {
      ManualWithPublishTasks.new(
        manual,
        attrs,
      )
    }
  end

  def load(manual, _record)
    tasks = ManualPublishTask.for_manual(manual)

    decorator.call(manual, publish_tasks: tasks)
  end

  def dump(_manual, _record)
    # PublishTasks are read only
    nil
  end

private

  attr_reader :decorator
end
