require "state_machine"

class SectionEdition
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "manual_section_editions"

  field :section_id,           type: String
  field :version_number,       type: Integer, default: 1
  field :title,                type: String
  field :slug,                 type: String
  field :summary, type: String
  field :body, type: String
  field :state, type: String
  field :change_note, type: String
  field :minor_update, type: Boolean
  field :public_updated_at, type: DateTime
  field :exported_at, type: DateTime

  validates :section_id, presence: true
  validates :slug, presence: true

  embeds_many :attachments, cascade_callbacks: true

  state_machine initial: :draft do
    event :publish do
      transition draft: :published
    end

    event :archive do
      transition all => :archived, :unless => :archived?
    end
  end

  scope :draft,               where(state: "draft")
  scope :published,           where(state: "published")
  scope :archived,            where(state: "archived")

  scope :with_slug_prefix, ->(slug) { where(slug: /^#{slug}.*/) }

  scope :two_latest_versions, ->(section_id) {
    where(section_id: section_id)
    .order_by([:version_number, :desc])
    .limit(2)
  }

  index section_id: 1
  index state: 1
  index updated_at: 1

  def build_attachment(attributes)
    attachments.build(
      attributes.merge(
        filename: attributes.fetch(:file).original_filename
      )
    )
  end
end
