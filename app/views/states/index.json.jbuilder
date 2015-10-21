json.array!(@states) do |state|
  json.extract! state, :id, :name, :abbr
  json.url state_url(state, format: :json)
end
