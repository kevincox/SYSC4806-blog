json.array!(@comments) do |comment|
  json.extract! comment, :id, :commentext, :author, :blogpost_id
  json.url comment_url(comment, format: :json)
end
