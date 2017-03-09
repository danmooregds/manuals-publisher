class AttachmentReporting
  POST_PUBLICATION_STATES = %w(published archived).freeze

  def initialize(first_period_start_date, last_time_period_days, attachment_file_extension)
    @first_period_start_date = first_period_start_date
    @last_time_period_days = last_time_period_days
    @attachment_file_extension = attachment_file_extension
  end

  def create_organisation_attachment_count_hash
    manual_records = ManualRecord.all
    unique_owning_organisation_slugs = manual_records.map(&:organisation_slug).uniq

    # Hash of organisation names mapped to three-element arrays of counts of PDFs, one count for each time period
    organisation_published_pdfs_counts_hash = Hash[unique_owning_organisation_slugs.map { |o| [o, [0, 0, 0]] }]

    manual_records.to_a.each do |manual|
      next unless manual.has_ever_been_published?

      unique_pdf_attachment_file_ids_for_manual = Set.new

      # Rather than examine each manual edition and its set of document editions and attachments in turn,
      # we instead get all unique document ids associated with this manual, then walk through
      # the editions of these documents in version order to find unique PDF attachments and their
      # publication times.
      all_unique_document_ids_for_manual(manual).each do |document_id|
        document_editions = SpecialistDocumentEdition.where(document_id: document_id).order(:version_number)

        document_editions.each do |document_edition|
          next if document_edition_never_published?(document_edition)

          document_edition.attachments.each do |attachment|
            next if unique_pdf_attachment_file_ids_for_manual.include? attachment.file_id
            next unless report_attachment_extension_matches?(attachment.filename)

            organisation_published_pdfs_counts_hash[manual.organisation_slug][0] += 1

            if document_published_after_date?(document_edition, @first_period_start_date)
              organisation_published_pdfs_counts_hash[manual.organisation_slug][1] += 1
            end

            if document_published_after_date?(document_edition, last_time_period_start_date)
              organisation_published_pdfs_counts_hash[manual.organisation_slug][2] += 1
            end

            unique_pdf_attachment_file_ids_for_manual << attachment.file_id
          end
        end
      end
    end

    titleize_keys(organisation_published_pdfs_counts_hash)

    organisation_published_pdfs_counts_hash
  end

private

  def titleize_keys(hash)
    hash.keys.each do |key|
      hash[key.titleize] = hash[key]
      hash.delete(key)
    end
  end

  def report_attachment_extension_matches?(filename)
    /.*\.#{@attachment_file_extension}/ =~ filename
  end

  def last_time_period_start_date
    @_last_time_period_start_date ||= @last_time_period_days.days.ago
  end

  def document_published_after_date?(document_edition, date)
    (document_edition.exported_at || document_edition.updated_at) >= date
  end

  def document_edition_never_published?(document_edition)
    !POST_PUBLICATION_STATES.include?(document_edition.state)
  end

  def all_unique_document_ids_for_manual(manual)
    manual.editions.map(&:document_ids).flatten.uniq
  end
end