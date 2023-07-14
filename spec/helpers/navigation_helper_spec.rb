require "spec_helper"
describe NavigationHelper, type: :helper do
  describe "#navigation_links_internal" do
    describe "before the what's new page expires" do
      before do
        travel_to Date.new(2023, 10, 31)
      end

      after do
        travel_back
      end

      it "returns a list of internal links" do
        expect(navigation_links_internal).to be_an_instance_of(Array)
      end

      it "includes a link to manuals" do
        expect(navigation_links_internal).to include(a_hash_including(text: "Manuals", href: manuals_path))
      end

      it "includes a link to what's new" do
        expect(navigation_links_internal).to include(a_hash_including(text: "What's new", href: whats_new_path))
      end
    end

    describe "once the what's new page expires" do
      before do
        travel_to Date.new(2023, 11, 1)
      end

      after do
        travel_back
      end

      it "returns a list of internal links" do
        expect(navigation_links_internal).to be_an_instance_of(Array)
      end

      it "includes a link to manuals" do
        expect(navigation_links_internal).to include(a_hash_including(text: "Manuals", href: manuals_path))
      end

      it "does not include a link to what's new" do
        expect(navigation_links_internal).not_to include(a_hash_including(text: "What's new", href: whats_new_path))
      end
    end

    it "sets the link to the current page as active" do
      request.path = manuals_path
      expect(navigation_links_internal).to include(a_hash_including(text: "Manuals", active: true))
      expect(navigation_links_internal).to include(a_hash_including(text: "What's new", active: false))
    end
  end

  describe "#navigation_links_auth" do
    let(:current_user) { User.create!(name: "John Doe") }

    it "returns a list of auth links" do
      expect(navigation_links_auth).to be_an_instance_of(Array)
    end

    it "includes a link to the user's profile" do
      expect(navigation_links_auth).to include(
        a_hash_including(text: "John Doe", href: Plek.external_url_for("signon")),
      )
    end

    it "includes a link to sign out" do
      expect(navigation_links_auth).to include(
        a_hash_including(text: "Log out", href: gds_sign_out_path),
      )
    end
  end
end
