ENV['RAILS_ENV'] = 'test'
require 'rspec'
require_relative '../lib/se/partition'
require 'active_record'
require 'active_support'

# lifted from db:test:prepare task
config = YAML::load(File.open(File.expand_path(File.dirname(__FILE__) + "/../config/database.yml")))
ActiveRecord::Base.configurations = config
ActiveRecord::Base.establish_connection(config['test'].merge('database' => 'postgres', 'schema_search_path' => 'public'))
ActiveRecord::Base.connection.drop_database(config['test']['database'])
ActiveRecord::Base.connection.create_database(config['test']['database'], config['test'])

class CreateModels < ActiveRecord::Migration
  def self.up
    execute 'drop table date_models cascade;' rescue nil
    create_table :date_models, :force => true do |t|
      t.datetime :key
    end
    add_index :date_models, :key, :unique => true

    execute 'drop table string_models cascade;' rescue nil
    create_table :string_models do |t|
      t.string :key
    end
    add_index :string_models, :key, :unique => true
  end

  def self.down
    drop_table :date_models
    drop_table :string_models
  end
end

class DateModel < ActiveRecord::Base ; end
class StringModel < ActiveRecord::Base ; end


describe SE::Partition do
  before(:all) do
    CreateModels.new.up
  end

  after(:all) do
    CreateModels.new.down
  end

  it 'partitions by date' do
    SE::Partition.partition(DateModel, :key, :verbose => false)
    DateModel.count.should be 0
    DateModel.connection.tables.count.should be 2
    DateModel.create!(:key => Time.now)
    DateModel.create!(:key => Time.now + 5.seconds)
    DateModel.create!(:key => Time.now + 1.day)
    DateModel.count.should be 3
    DateModel.connection.tables.count.should be 4

    DateModel.connection.tables.select {|ii| /date_models_/ =~ ii}.each do |table|
      DateModel.connection.indexes(table).size.should be(2)
    end
  end

  it 'prunes tables by date' do
    SE::Partition.partition(DateModel, :key, :verbose => false)
    10.times do |ii|
      DateModel.create!(:key => Time.now - ii.days)
    end

    initial_count = DateModel.connection.tables.count
    SE::Partition.prune(DateModel, 15).should be 0
    DateModel.connection.tables.count.should == initial_count

    SE::Partition.prune(DateModel, 5).should be 6
    DateModel.connection.tables.count == initial_count - 5
  end

  it 'partitions by string' do
    SE::Partition.partition(StringModel, :key, :verbose => false)
    StringModel.count.should be 0
    initial_count = StringModel.connection.tables.count
    StringModel.create!(:key => '7Day-2010-01-01')
    StringModel.create!(:key => '7day-2010-01-01')
    StringModel.create!(:key => '1Month-2010-01-01')
    StringModel.connection.tables.count.should == initial_count + 2
    StringModel.count.should be 3

    StringModel.connection.tables.select {|ii| /string_models_/ =~ ii}.each do |table|
      StringModel.connection.indexes(table).size.should be 2
    end
  end
end
