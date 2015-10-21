class State
  include Mongoid::Document
  field :name, type: String
  field :abbv, type: String
  field :nonresident, type: Boolean
  field :residentrec, type: Array
  field :nonresidentrec, type: Array
  field :point, type: Array
end
