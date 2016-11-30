class ManualRelocator
  attr_reader :from_slug, :to_slug

  def initialize(from_slug, to_slug)
    @from_slug = from_slug
    @to_slug = to_slug
  end

  def self.move(from_slug, to_slug)
    new(from_slug, to_slug).move!
  end

  def move!
    redirect_and_remove
    reslug
  end

  def old_manual
    @old_manual ||= fetch_manual(to_slug)
  end

  def new_manual
    @new_manual ||= fetch_manual(from_slug)
  end

private

  def fetch_manual(slug)
    manuals = ManualRecord.where(slug: slug)
    raise "No manual found for slug '#{slug}'" if manuals.count == 0
    raise "More than one manual found for slug '#{slug}'" if manuals.count > 1
    manuals.first
  end

  def redirect_and_remove
    if old_manual.editions.any?
      # Redirect all sections of the manual we're going to remove
      # to prevent dead bookmarked URLs.
      document_ids = old_manual.editions.flat_map(&:document_ids).uniq

      document_ids.each do |document_id|
        editions = SpecialistDocumentEdition.where(document_id: document_id)
        edition = editions.last

        begin
          puts "Redirecting content item '/#{edition.slug}' to '/#{old_manual.slug}'"
          publishing_api.unpublish(edition.document_id,
                                   type: "redirect",
                                   alternative_path: "/#{old_manual.slug}",
                                   discard_drafts: true)
        rescue GdsApi::HTTPNotFound
          puts "Content item with content_id #{document_id} not present in the publishing API"
        end

        # Destroy all the editons of this manual as it's going away
        editions.map(&:destroy)
      end
    end

    puts "Destroying old PublicationLogs for #{old_manual.slug}"
    PublicationLog.change_notes_for(old_manual.slug).each { |log| log.destroy }

    # Destroy the manual record
    puts "Destroying manual #{old_manual._id}"
    old_manual.destroy
  end

  def reslug
    # Reslug the manual sections
    document_ids = new_manual.editions.flat_map(&:document_ids).uniq
    document_ids.each do |document_id|
      sections = SpecialistDocumentEdition.where(document_id: document_id)
      sections.each do |section|
        reslug_msg = "Reslugging section '#{section.slug}'"
        new_section_slug = section.slug.gsub(from_slug, to_slug)
        puts "#{reslug_msg} as '#{section.slug}'"
        section.set(:slug, new_section_slug)
      end
    end

    # Reslug the manual
    puts "Reslugging manual '#{new_manual.slug}' as '#{to_slug}'"
    new_manual.set(:slug, to_slug)

    # Reslug the existing publication logs
    puts "Reslugging publication logs for #{from_slug} to #{to_slug}"
    PublicationLog.change_notes_for(from_slug).each do |publication_log|
      publication_log.set(:slug, publication_log.slug.gsub(from_slug, to_slug))
    end

    # Clean up manual sections belonging to the temporary manual path
    document_ids.each do |document_id|
      puts "Redirecting #{document_id} to '/#{to_slug}'"
      most_recent_edition = SpecialistDocumentEdition.where(document_id: document_id).order_by([:version_number, :desc]).first
      publishing_api.unpublish(document_id,
                               type: "redirect",
                               alternative_path: "/#{most_recent_edition.slug}",
                               discard_drafts: true)
    end

    # Clean up the drafted manual in the Publishing API
    puts "Redirecting #{new_manual.manual_id} to '/#{to_slug}'"
    publishing_api.unpublish(new_manual.manual_id,
                             type: "redirect",
                             alternative_path: "/#{to_slug}",
                             discard_drafts: true)
  end

  def publishing_api
    ManualsPublisherWiring.get(:publishing_api_v2)
  end
end
