require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    cached_columns = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        "#{self.table_name}"
    SQL
    @columns = cached_columns.first.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |column|
      col_name = column.to_s

      define_method(col_name) do
        attributes[column]
      end

      define_method(col_name + "=") do |col_val|
        attributes[column] = col_val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    all = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        "#{self.table_name}"
    SQL
    parse_all(all)
  end

  def self.parse_all(results)
    results.map { |hash| self.new(hash) }
  end

  def self.find(id)
    var = self.parse_all DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        "#{self.table_name}"
      WHERE
        id = ?
    SQL
    var.first
  end

  def initialize(params = {})
    self.class.send(:finalize!)
    params.each do |attr_name, val|
      sym_attr = attr_name.to_sym
      raise "unknown attribute '#{ attr_name }'" unless self.class.columns.include?(sym_attr)
      self.send("#{attr_name}=", val)
    end
  end

  def attributes
    @attributes ||= Hash.new
  end

  def attribute_values
    attributes.values
    #self.send()
  end

  def insert
    col_names = self.class.columns.reject{ |col| col == :id }.join(', ')
    question_marks = Array.new(self.class.columns.length - 1) { "?" }.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names = self.class.columns.join(' = ?, ') + ' = ?'
    question_marks = Array.new(self.class.columns.length - 1) { "?" }.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values)
      UPDATE
        #{self.class.table_name}
      SET
        #{col_names}
      WHERE
        id = #{self.id}
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
