require "section_repository"
require "manual_repository"
require "section_edition"
require "marshallers/document_association_marshaller"
require "marshallers/manual_publish_task_association_marshaller"
require "manual_publish_task"
require "manual_with_publish_tasks"
require "manual"
require "manual_record"

class RepositoryRegistry
  def organisation_scoped_manual_repository_factory
    ->(organisation_slug) {
      scoped_manual_repository(
        ManualRecord.where(organisation_slug: organisation_slug)
      )
    }
  end

  def manual_repository
    scoped_manual_repository(ManualRecord.all)
  end

  def scoped_manual_repository(collection)
    ManualRepository.new(
      association_marshallers: [
        SectionAssociationMarshaller.new(
          section_repository_factory: section_repository_factory,
          decorator: ->(manual, attrs) {
            DocumentFactoryRegistry.new.manual_with_sections.call(manual, attrs)
          }
        ),
        ManualPublishTaskAssociationMarshaller.new(
          collection: ManualPublishTask,
          decorator: ->(manual, attrs) {
            ManualWithPublishTasks.new(
              manual,
              attrs,
            )
          }
        ),
      ],
      collection: collection,
    )
  end

  def section_repository_factory
    ->(manual) {
      section_factory = SectionFactory.new(manual)

      SectionRepository.new(
        section_factory: section_factory,
      )
    }
  end

  def associationless_manual_repository
    associationless_scoped_manual_repository(ManualRecord.all)
  end

  def associationless_scoped_manual_repository(collection)
    ManualRepository.new(
      collection: collection,
    )
  end

  def associationless_organisation_scoped_manual_repository_factory
    ->(organisation_slug) {
      associationless_scoped_manual_repository(
        ManualRecord.where(organisation_slug: organisation_slug)
      )
    }
  end
end
