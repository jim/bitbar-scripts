require "json"

require "./api"

DOCS_ENDPOINT = "https://docs.googleapis.com/v1/documents"

module Google
  class Docs < API
    def fetch_doc(id)
      response = fetch(DOCS_ENDPOINT + "/" + id)
      if response.status.code == 200
        cache_write("data/docs/#{id}", response.body)
      else
        fail(response)
      end
    end

    def cached_document(id)
      key = "data/docs/#{id}"
      cached = cache_read(key)
      unless cached
        fetch_doc(id)
        cached = cache_read(key)
      end
      if cached
        Document.from_json(cached)
      else
        LoadingDocument.new(id: id)
      end
    end
  end

  class LoadingDocument
    def initialize(@id : String)
    end

    def title
      "loading"
    end

    def url
      "https://docs.google.com/document/d/#{@id}/edit"
    end
  end

  class Document
    JSON.mapping(
      title: String,
      id: {type: String, key: "documentId"}
    )

    def url
      "https://docs.google.com/document/d/#{id}/edit"
    end
  end
end

id = "1aBTsEh5gKxTN1tEhN4Lf3h2W_vPqx5VMAkUqPARixRI"
