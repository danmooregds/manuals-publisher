require "section_repository"
require "manual_repository"
require "section_edition"
require "marshallers/section_association_marshaller"
require "marshallers/manual_publish_task_association_marshaller"
require "manual_publish_task"
require "manual_with_publish_tasks"
require "manual"
require "manual_record"
require "manual_with_sections"

class RepositoryRegistry
  def manual_repository
    scoped_manual_repository(ManualRecord.all)
  end

  def scoped_manual_repository(collection)
    ScopedManualRepository.new(collection)
  end
end
