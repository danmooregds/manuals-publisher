require "email_alert_exporter"
require "formatters/maib_report_publication_alert_formatter"

class MaibReportObserversRegistry < AbstractSpecialistDocumentObserversRegistry

private
  def content_api_exporter
    SpecialistPublisherWiring.get(:maib_report_content_api_exporter)
  end

  def panopticon_exporter
    SpecialistPublisherWiring.get(:maib_report_panopticon_registerer)
  end

  def rummager_withdrawer
    SpecialistPublisherWiring.get(:maib_report_rummager_deleter)
  end

  def rummager_exporter
    SpecialistPublisherWiring.get(:maib_report_rummager_indexer)
  end

  def content_api_withdrawer
    SpecialistPublisherWiring.get(:specialist_document_content_api_withdrawer)
  end

  def publication_alert_formatter(document)
    MaibReportPublicationAlertFormatter.new(
      url_maker: url_maker,
      document: document,
    )
  end
end
