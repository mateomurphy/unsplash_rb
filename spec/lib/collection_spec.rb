require "spec_helper"

describe Unsplash::Collection do

  let (:collection_id) { 201 }
  let (:curated_id) { 90 }
  let (:fake_id)  { 1234 }

  describe "#find" do
    it "returns a Collection object" do
      VCR.use_cassette("collections") do
        @collection = Unsplash::Collection.find(collection_id)
      end

      expect(@collection).to be_a Unsplash::Collection
    end

    it "errors if the collection doesn't exist" do
      expect {
        VCR.use_cassette("collections") do
          @collection = Unsplash::Collection.find(fake_id)
        end
      }.to raise_error Unsplash::Error
    end

    it "parses the nested user object" do
      VCR.use_cassette("collections") do
        @collection = Unsplash::Collection.find(collection_id)
      end

      expect(@collection.user).to be_an Unsplash::User
    end

    it "parses the cover photo" do
      VCR.use_cassette("collections") do
        @collection = Unsplash::Collection.find(collection_id)
      end
      expect(@collection.cover_photo).to be_an Unsplash::Photo
    end

    it "returns an uncurated collection" do
      VCR.use_cassette("collections") do
        @collection = Unsplash::Collection.find(collection_id)
      end

      expect(@collection.curated).to eq false
    end

    it "returns a curated collection" do
      VCR.use_cassette("collections") do
        @collection = Unsplash::Collection.find(curated_id, true)
      end

      expect(@collection.curated).to eq true
    end
  end

  describe "#all" do
    it "returns an array of Collections" do
      VCR.use_cassette("collections") do
        @collections = Unsplash::Collection.all(1, 12)
      end

      expect(@collections).to be_an Array
      expect(@collections.size).to eq 12
    end
    
    it "parses the nested user objects" do
      VCR.use_cassette("collections") do
        @collections = Unsplash::Collection.all(1, 12)
      end

      expect(@collections.map(&:user)).to all (be_an Unsplash::User)
    end

  end

  describe "#photos" do
    before :each do
      VCR.use_cassette("collections") do
        @photos = Unsplash::Collection.find(collection_id).photos
      end
    end

    it "returns an array of Photos" do
      expect(@photos).to be_an Array
      expect(@photos).to all (be_an Unsplash::Photo)
    end
  end

  describe "#create" do
    it "returns Collection object" do
      stub_oauth_authorization
      VCR.use_cassette("collections") do
        @collection = Unsplash::Collection.create(title: "Ultimate Faves", private: true)
      end

      expect(@collection).to be_a Unsplash::Collection
    end

    it "fails without Bearer token" do
      expect {
        VCR.use_cassette("collections", match_requests_on: [:method, :path, :body]) do
          Unsplash::Collection.create(title: "Ultimate Faves", private: true)
        end
      }.to raise_error Unsplash::Error
    end
  end

  describe "#update" do
    before :each do
      stub_oauth_authorization
      VCR.use_cassette("collections") do
        @collection = Unsplash::Collection.create(title: "Ultimate Faves")
      end
    end

    it "returns Collection object" do
      VCR.use_cassette("collections") do
        @collection = @collection.update(title: "Penultimate Faves")
      end
      
      expect(@collection).to be_a Unsplash::Collection
    end

    it "updates the Collection object" do
      VCR.use_cassette("collections") do
        @collection = Unsplash::Collection.find(@collection.id)
        @collection.update(title: "Best Picturez")
      end
      
      expect(@collection.title).to eq "Best Picturez"
    end

  end

  describe "#destroy" do

    it "returns true on success" do
      stub_oauth_authorization
      VCR.use_cassette("collections") do
        collection = Unsplash::Collection.find(302)
        expect(collection.destroy).to eq true
      end
    end

    it "raises on failure" do
      expect {
        stub_oauth_authorization
        VCR.use_cassette("collections") do
          collection = Unsplash::Collection.find(201) # exists but does not belong to user
          collection.destroy
        end
      }.to raise_error OAuth2::Error
    end

  end

  describe "#add" do
    before :each do
      VCR.use_cassette("photos") do
        @photo = Unsplash::Photo.find("tAKXap853rY")
      end
    end

    it "returns a metadata hash" do
      stub_oauth_authorization
      
      VCR.use_cassette("collections") do
        collection = Unsplash::Collection.find(301)
        meta = collection.add(@photo)
        expect(meta[:collection_id]).to eq collection.id
        expect(meta[:photo_id]).to eq @photo.id
      end
    end
  end


  describe "#remove" do
    before :each do
      VCR.use_cassette("photos") do
        @photo = Unsplash::Photo.find("tAKXap853rY")
      end
    end

    it "returns true on success" do
      stub_oauth_authorization
      VCR.use_cassette("collections") do
        collection = Unsplash::Collection.find(301)
        expect(collection.remove(@photo)).to be true
      end
    end
  end

end