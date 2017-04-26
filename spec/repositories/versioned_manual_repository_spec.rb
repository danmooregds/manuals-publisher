require "spec_helper"

RSpec.describe VersionedManualRepository do
  let(:manual) { Manual.find(manual_id, User.gds_editor) }

  context "when the provided id refers to the first draft of a manual" do
    let(:manual_id) { SecureRandom.uuid }
    let(:manual_record) { ManualRecord.create(manual_id: manual_id, slug: "guidance/my-amazing-manual", organisation_slug: "cabinet-office") }
    let(:manual_edition) { ManualRecord::Edition.new(section_ids: %w(12345 67890), version_number: 1, state: "draft") }
    let!(:section_1) { FactoryGirl.create(:section_edition, slug: "#{manual_record.slug}/section-1", section_id: "12345", version_number: 1, state: "draft") }
    let!(:section_2) { FactoryGirl.create(:section_edition, slug: "#{manual_record.slug}/section-2", section_id: "67890", version_number: 1, state: "draft") }
    before do
      manual_record.editions << manual_edition
    end

    context "the published version returned" do
      it "is blank" do
        expect(manual.current_versions[:published]).to be_nil
      end
    end

    context "the draft version returned" do
      it "is the first draft as a Manual instance" do
        result = manual.current_versions[:draft]

        expect(result).to be_a ::Manual
        expect(result.id).to eq manual_id
        expect(result.state).to eq "draft"
        expect(result.version_number).to eq 1
        expect(result.slug).to eq "guidance/my-amazing-manual"
      end

      it "has the first draft of the section editions as Section instances attached" do
        result = manual.current_versions[:draft]

        sections = result.sections.to_a
        expect(sections.size).to eq 2

        section_1 = sections[0]
        expect(section_1).to be_a ::Section
        expect(section_1.id).to eq "12345"
        expect(section_1).to be_draft
        expect(section_1.version_number).to eq 1
        expect(section_1.slug).to eq "guidance/my-amazing-manual/section-1"

        section_2 = sections[1]
        expect(section_2).to be_a ::Section
        expect(section_2.id).to eq "67890"
        expect(section_2).to be_draft
        expect(section_2.version_number).to eq 1
        expect(section_2.slug).to eq "guidance/my-amazing-manual/section-2"
      end
    end
  end

  context "when the provided id refers to manual that has been published once" do
    let(:manual_id) { SecureRandom.uuid }
    let(:manual_record) { ManualRecord.create(manual_id: manual_id, slug: "guidance/my-amazing-manual", organisation_slug: "cabinet-office") }
    let(:manual_edition) { ManualRecord::Edition.new(section_ids: %w(12345 67890), version_number: 1, state: "published") }
    let!(:section_1) { FactoryGirl.create(:section_edition, slug: "#{manual_record.slug}/section-1", section_id: "12345", version_number: 1, state: "published") }
    let!(:section_2) { FactoryGirl.create(:section_edition, slug: "#{manual_record.slug}/section-2", section_id: "67890", version_number: 1, state: "published") }
    before do
      manual_record.editions << manual_edition
    end

    context "the published version returned" do
      it "is the published version as a Manual instance" do
        result = manual.current_versions[:published]

        expect(result).to be_a ::Manual
        expect(result.id).to eq manual_id
        expect(result.state).to eq "published"
        expect(result.version_number).to eq 1
        expect(result.slug).to eq "guidance/my-amazing-manual"
      end

      it "has the published version of the section editions as Section instances attached" do
        result = manual.current_versions[:published]

        sections = result.sections.to_a
        expect(sections.size).to eq 2

        section_1 = sections[0]
        expect(section_1).to be_a ::Section
        expect(section_1.id).to eq "12345"
        expect(section_1).to be_published
        expect(section_1.version_number).to eq 1
        expect(section_1.slug).to eq "guidance/my-amazing-manual/section-1"

        section_2 = sections[1]
        expect(section_2).to be_a ::Section
        expect(section_2.id).to eq "67890"
        expect(section_2).to be_published
        expect(section_2.version_number).to eq 1
        expect(section_2.slug).to eq "guidance/my-amazing-manual/section-2"
      end
    end

    context "the draft version returned" do
      it "is blank" do
        expect(manual.current_versions[:draft]).to be_nil
      end
    end
  end

  context "when the provided id refers to manual that has been withdrawn once" do
    let(:manual_id) { SecureRandom.uuid }
    let(:manual_record) { ManualRecord.create(manual_id: manual_id, slug: "guidance/my-amazing-manual", organisation_slug: "cabinet-office") }
    let(:manual_edition) { ManualRecord::Edition.new(section_ids: %w(12345 67890), version_number: 1, state: "withdrawn") }
    let!(:section_1) { FactoryGirl.create(:section_edition, slug: "#{manual_record.slug}/section-1", section_id: "12345", version_number: 1, state: "archived") }
    let!(:section_2) { FactoryGirl.create(:section_edition, slug: "#{manual_record.slug}/section-2", section_id: "67890", version_number: 1, state: "archived") }
    before do
      manual_record.editions << manual_edition
    end

    context "the published version returned" do
      it "is blank" do
        expect(manual.current_versions[:published]).to be_nil
      end
    end

    context "the draft version returned" do
      it "is blank" do
        expect(manual.current_versions[:draft]).to be_nil
      end
    end
  end

  context "when the provided id refers to manual that has been published once and has a new draft waiting" do
    let(:manual_id) { SecureRandom.uuid }
    let(:manual_record) { ManualRecord.create(manual_id: manual_id, slug: "guidance/my-amazing-manual", organisation_slug: "cabinet-office") }
    let(:manual_published_edition) { ManualRecord::Edition.new(section_ids: %w(12345 67890), version_number: 1, state: "published") }
    let(:manual_draft_edition) { ManualRecord::Edition.new(section_ids: %w(12345 67890), version_number: 2, state: "draft") }
    before do
      manual_record.editions << manual_published_edition
      manual_record.editions << manual_draft_edition
    end

    context "including new drafts of all sections" do
      let!(:section_1_published) { FactoryGirl.create(:section_edition, slug: "#{manual_record.slug}/section-1", section_id: "12345", version_number: 1, state: "published") }
      let!(:section_2_published) { FactoryGirl.create(:section_edition, slug: "#{manual_record.slug}/section-2", section_id: "67890", version_number: 1, state: "published") }
      let!(:section_1_draft) { FactoryGirl.create(:section_edition, slug: "#{manual_record.slug}/section-1", section_id: "12345", version_number: 2, state: "draft") }
      let!(:section_2_draft) { FactoryGirl.create(:section_edition, slug: "#{manual_record.slug}/section-2", section_id: "67890", version_number: 2, state: "draft") }

      context "the published version returned" do
        it "is the published version as a Manual instance" do
          result = manual.current_versions[:published]

          expect(result).to be_a ::Manual
          expect(result.id).to eq manual_id
          expect(result.state).to eq "published"
          expect(result.version_number).to eq 1
          expect(result.slug).to eq "guidance/my-amazing-manual"
        end

        it "has the published versions of the section editions as Section instances attached" do
          result = manual.current_versions[:published]

          sections = result.sections.to_a
          expect(sections.size).to eq 2

          section_1 = sections[0]
          expect(section_1).to be_a ::Section
          expect(section_1.id).to eq "12345"
          expect(section_1).to be_published
          expect(section_1.version_number).to eq 1
          expect(section_1.slug).to eq "guidance/my-amazing-manual/section-1"

          section_2 = sections[1]
          expect(section_2).to be_a ::Section
          expect(section_2.id).to eq "67890"
          expect(section_2).to be_published
          expect(section_2.version_number).to eq 1
          expect(section_2.slug).to eq "guidance/my-amazing-manual/section-2"
        end
      end

      context "the draft version returned" do
        it "is the new draft as a Manual instance" do
          result = manual.current_versions[:draft]

          expect(result).to be_a ::Manual
          expect(result.id).to eq manual_id
          expect(result.state).to eq "draft"
          expect(result.version_number).to eq 2
          expect(result.slug).to eq "guidance/my-amazing-manual"
        end

        it "has the new drafts of the section editions as Section instances attached" do
          result = manual.current_versions[:draft]

          sections = result.sections.to_a
          expect(sections.size).to eq 2

          section_1 = sections[0]
          expect(section_1).to be_a ::Section
          expect(section_1.id).to eq "12345"
          expect(section_1).to be_draft
          expect(section_1.version_number).to eq 2
          expect(section_1.slug).to eq "guidance/my-amazing-manual/section-1"

          section_2 = sections[1]
          expect(section_2).to be_a ::Section
          expect(section_2.id).to eq "67890"
          expect(section_2).to be_draft
          expect(section_2.version_number).to eq 2
          expect(section_2.slug).to eq "guidance/my-amazing-manual/section-2"
        end
      end
    end

    context "without new drafts of any sections" do
      let!(:section_1_published) { FactoryGirl.create(:section_edition, slug: "#{manual_record.slug}/section-1", section_id: "12345", version_number: 1, state: "published") }
      let!(:section_2_published) { FactoryGirl.create(:section_edition, slug: "#{manual_record.slug}/section-2", section_id: "67890", version_number: 1, state: "published") }

      context "the published version returned" do
        it "is the published version as a Manual instance" do
          result = manual.current_versions[:published]

          expect(result).to be_a ::Manual
          expect(result.id).to eq manual_id
          expect(result.state).to eq "published"
          expect(result.version_number).to eq 1
          expect(result.slug).to eq "guidance/my-amazing-manual"
        end

        it "has the published versions of the section editions as Section instances attached" do
          result = manual.current_versions[:published]

          sections = result.sections.to_a
          expect(sections.size).to eq 2

          section_1 = sections[0]
          expect(section_1).to be_a ::Section
          expect(section_1.id).to eq "12345"
          expect(section_1).to be_published
          expect(section_1.version_number).to eq 1
          expect(section_1.slug).to eq "guidance/my-amazing-manual/section-1"

          section_2 = sections[1]
          expect(section_2).to be_a ::Section
          expect(section_2.id).to eq "67890"
          expect(section_2).to be_published
          expect(section_2.version_number).to eq 1
          expect(section_2.slug).to eq "guidance/my-amazing-manual/section-2"
        end
      end

      context "the draft version returned" do
        it "is the new draft as a Manual instance" do
          result = manual.current_versions[:draft]

          expect(result).to be_a ::Manual
          expect(result.id).to eq manual_id
          expect(result.state).to eq "draft"
          expect(result.version_number).to eq 2
          expect(result.slug).to eq "guidance/my-amazing-manual"
        end

        it "has the published versions of the section editions as Section instances attached" do
          result = manual.current_versions[:published]

          sections = result.sections.to_a
          expect(sections.size).to eq 2

          section_1 = sections[0]
          expect(section_1).to be_a ::Section
          expect(section_1.id).to eq "12345"
          expect(section_1).to be_published
          expect(section_1.version_number).to eq 1
          expect(section_1.slug).to eq "guidance/my-amazing-manual/section-1"

          section_2 = sections[1]
          expect(section_2).to be_a ::Section
          expect(section_2.id).to eq "67890"
          expect(section_2).to be_published
          expect(section_2.version_number).to eq 1
          expect(section_2.slug).to eq "guidance/my-amazing-manual/section-2"
        end
      end
    end

    context "including new drafts of some sections" do
      let!(:section_1_published) { FactoryGirl.create(:section_edition, slug: "#{manual_record.slug}/section-1", section_id: "12345", version_number: 1, state: "published") }
      let!(:section_2_published) { FactoryGirl.create(:section_edition, slug: "#{manual_record.slug}/section-2", section_id: "67890", version_number: 1, state: "published") }
      let!(:section_2_draft) { FactoryGirl.create(:section_edition, slug: "#{manual_record.slug}/section-2", section_id: "67890", version_number: 2, state: "draft") }

      context "the published version returned" do
        it "is the published version as a Manual instance" do
          result = manual.current_versions[:published]

          expect(result).to be_a ::Manual
          expect(result.id).to eq manual_id
          expect(result.state).to eq "published"
          expect(result.version_number).to eq 1
          expect(result.slug).to eq "guidance/my-amazing-manual"
        end

        it "has the published versions of the section editions as Section instances attached" do
          result = manual.current_versions[:published]

          sections = result.sections.to_a
          expect(sections.size).to eq 2

          section_1 = sections[0]
          expect(section_1).to be_a ::Section
          expect(section_1.id).to eq "12345"
          expect(section_1).to be_published
          expect(section_1.version_number).to eq 1
          expect(section_1.slug).to eq "guidance/my-amazing-manual/section-1"

          section_2 = sections[1]
          expect(section_2).to be_a ::Section
          expect(section_2.id).to eq "67890"
          expect(section_2).to be_published
          expect(section_2.version_number).to eq 1
          expect(section_2.slug).to eq "guidance/my-amazing-manual/section-2"
        end
      end

      context "the draft version returned" do
        it "is the new draft as a Manual instance" do
          result = manual.current_versions[:draft]

          expect(result).to be_a ::Manual
          expect(result.id).to eq manual_id
          expect(result.state).to eq "draft"
          expect(result.version_number).to eq 2
          expect(result.slug).to eq "guidance/my-amazing-manual"
        end

        it "has correct draft or published version of the section editions as Section instances attached" do
          result = manual.current_versions[:draft]

          sections = result.sections.to_a
          expect(sections.size).to eq 2

          section_1 = sections[0]
          expect(section_1).to be_a ::Section
          expect(section_1.id).to eq "12345"
          expect(section_1).to be_published
          expect(section_1.version_number).to eq 1
          expect(section_1.slug).to eq "guidance/my-amazing-manual/section-1"

          section_2 = sections[1]
          expect(section_2).to be_a ::Section
          expect(section_2.id).to eq "67890"
          expect(section_2).to be_draft
          expect(section_2.version_number).to eq 2
          expect(section_2.slug).to eq "guidance/my-amazing-manual/section-2"
        end
      end
    end
  end
end
