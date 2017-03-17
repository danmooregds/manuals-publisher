require "spec_helper"

describe SectionRepository do
  let(:section_repository) do
    SectionRepository.new(
      section_factory: section_factory,
    )
  end

  let(:section_factory) { double(:section_factory, call: document) }

  let(:document_id) { "document-id" }
  let(:document) {
    Section.new(slug_generator, document_id, editions, edition_factory)
  }

  let(:slug_generator) { double(:slug_generator) }

  let(:edition_factory) { double(:edition_factory) }
  let(:editions) { [new_draft_edition] }

  let(:new_draft_edition) {
    double(
      :new_draft_edition,
      title: "Example document about oil reserves",
      slug: "example-document-about-oil-reserves",
      "document_id=": nil,
      "slug=": nil,
      changed?: true,
      save!: true,
      published?: false,
      draft?: true,
      errors: {},
      publish: nil,
      version_number: 2,
      archive: nil,
    )
  }

  def build_published_edition(version: 1)
    double(
      :published_edition,
      title: "Example document about oil reserves #{version}",
      "document_id=": nil,
      changed?: false,
      save!: nil,
      archive: nil,
      published?: true,
      draft?: false,
      version_number: version,
    )
  end

  let(:published_edition) { build_published_edition }

  it "supports the fetch interface" do
    expect(section_repository).to be_a_kind_of(Fetchable)
  end

  describe "#all" do
    before do
      @edition_1, @edition_2 = [2, 1].map do |n|
        document_id = "document-id-#{n}"

        edition = FactoryGirl.create(:section_edition,
                                     document_id: document_id,
                                     updated_at: n.days.ago)

        allow(section_factory).to receive(:call)
          .with(document_id, [edition])
          .and_return(Section.new(slug_generator, document_id, [edition]))

        edition
      end
    end

    it "returns all documents by date updated desc" do
      expect(
        section_repository.all.map(&:title).to_a
      ).to eq([@edition_2, @edition_1].map(&:title))
    end
  end

  describe "#[]" do
    let(:editions_proxy) { double(:editions_proxy, to_a: editions).as_null_object }
    let(:editions)       { [published_edition] }

    before do
      allow(Section).to receive(:new).and_return(document)
      allow(SectionEdition).to receive(:all)
        .and_return(editions_proxy)
    end

    it "populates the document with all editions for that document id" do
      section_repository[document_id]

      expect(section_factory).to have_received(:call).with(document_id, editions)
    end

    it "returns the document" do
      expect(section_repository[document_id]).to eq(document)
    end

    context "when there are no editions" do
      before do
        allow(editions_proxy).to receive(:to_a).and_return([])
      end

      it "returns nil" do
        expect(section_repository[document_id]).to be_nil
      end
    end
  end

  describe "#store(document)" do
    context "with a valid editions" do
      let(:previous_edition) { build_published_edition(version: 1) }
      let(:current_published_edition) { build_published_edition(version: 2) }

      let(:editions) {
        [
          previous_edition,
          current_published_edition,
          new_draft_edition,
        ]
      }

      it "returns self" do
        expect(section_repository.store(document)).to be(
          section_repository
        )
      end

      it "saves the the two most recent editions" do
        section_repository.store(document)

        expect(new_draft_edition).to have_received(:save!)
        expect(current_published_edition).to have_received(:save!)
        expect(previous_edition).not_to have_received(:save!)
      end
    end
  end
end