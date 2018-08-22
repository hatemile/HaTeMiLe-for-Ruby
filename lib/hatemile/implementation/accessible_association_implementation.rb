# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require File.join(
  File.dirname(File.dirname(__FILE__)),
  'accessible_association'
)
require File.join(
  File.dirname(File.dirname(__FILE__)),
  'util',
  'common_functions'
)
require File.join(
  File.dirname(File.dirname(__FILE__)),
  'util',
  'id_generator'
)

##
# The Hatemile module contains the interfaces with the acessibility solutions.
module Hatemile
  ##
  # The Hatemile::Implementation module contains the official implementation of
  # interfaces solutions.
  module Implementation
    ##
    # The AccessibleAssociationImplementation class is official implementation
    # of AccessibleAssociation.
    class AccessibleAssociationImplementation < AccessibleAssociation
      public_class_method :new

      protected

      ##
      # Returns a list that represents the table.
      #
      # @param part [Hatemile::Util::Html::HTMLDOMElement] The table header,
      #   table footer or table body.
      # @return [Array<Array<Hatemile::Util::Html::HTMLDOMElement>>] The list
      #   that represents the table.
      def generate_part(part)
        rows = @parser.find(part).find_children('tr').list_results
        table = []
        rows.each do |row|
          table.push(
            generate_colspan(
              @parser.find(row).find_children('td,th').list_results
            )
          )
        end
        generate_rowspan(table)
      end

      ##
      # Returns a list that represents the table with the rowspans.
      #
      # @param rows [Array<Array<Hatemile::Util::Html::HTMLDOMElement>>] The
      #   list that represents the table without the rowspans.
      # @return [Array<Array<Hatemile::Util::Html::HTMLDOMElement>>] The list
      #   that represents the table with the rowspans.
      def generate_rowspan(rows)
        copy = [].concat(rows)
        table = []
        unless rows.empty?
          length_rows = rows.size
          (0..length_rows - 1).each do |i|
            column_index = 0
            cells = [].concat(copy[i])
            table[i] = [] if table.size <= i
            length_cells = cells.size
            (0..length_cells - 1).each do |j|
              cell = cells[j]
              m = j + column_index
              row = table[i]
              until row[m].nil?
                column_index += 1
                m = j + column_index
              end
              row[m] = cell

              next unless cell.has_attribute?('rowspan')

              rowspan = cell.get_attribute('rowspan').to_i

              next unless rowspan > 1

              (1..rowspan - 1).each do |k|
                n = i + k
                table[n] = [] if table[n].nil?
                table[n][m] = cell
              end
            end
          end
        end
        table
      end

      ##
      # Returns a list that represents the line of table with the colspans.
      #
      # @param row [Array<Hatemile::Util::Html::HTMLDOMElement>] The list that
      #   represents the line of table without the colspans.
      # @return [Array<Hatemile::Util::Html::HTMLDOMElement>] The list that
      #   represents the line of table with the colspans.
      def generate_colspan(row)
        copy = [].concat(row)
        cells = [].concat(row)
        size = row.size
        (0..size - 1).each do |i|
          cell = cells[i]

          next unless cell.has_attribute?('colspan')

          colspan = cell.get_attribute('colspan').to_i

          next unless colspan > 1

          (1..colspan - 1).each do |j|
            copy.insert(i + j, cell)
          end
        end
        copy
      end

      ##
      # Validate the list that represents the table header.
      #
      # @param header [Array<Array<Hatemile::Util::Html::HTMLDOMElement>>] The
      #   list that represents the table header.
      # @return [Boolean] True if the table header is valid or false if the
      #   table header is not valid.
      def valid_header?(header)
        return false if header.empty?
        length = -1
        header.each do |row|
          return false if row.empty?
          length = row.size if length == -1
          return false if row.size != length
        end
        true
      end

      ##
      # Returns a list with ids of rows of same column.
      #
      # @param header [Array<Array<Hatemile::Util::Html::HTMLDOMElement>>] The
      #   list that represents the table header.
      # @param index [Integer] The index of columns.
      # @return [Array<String>] The list with ids of rows of same column.
      def return_list_ids_columns(header, index)
        ids = []
        header.each do |row|
          if row[index].has_attribute?('scope') &&
             row[index].get_attribute('scope') == 'col'
            ids.push(row[index].get_attribute('id'))
          end
        end
        ids
      end

      ##
      # Fix the table body or table footer.
      #
      # @param element [Hatemile::Util::Html::HTMLDOMElement] The table body or
      #   table footer.
      # @return [void]
      def fix_body_or_footer(element)
        table = generate_part(element)
        headers_ids = []
        table.each do |cells|
          headers_ids.clear
          cells.each do |cell|
            next unless cell.get_tag_name == 'TH' &&
                        Hatemile::Util::CommonFunctions.is_valid_element?(cell)

            @id_generator.generate_id(cell)
            headers_ids.push(cell.get_attribute('id'))
            cell.set_attribute('scope', 'row')
          end

          next if headers_ids.empty?

          cells.each do |cell|
            next unless cell.get_tag_name == 'TD' &&
                        Hatemile::Util::CommonFunctions.is_valid_element?(cell)

            headers = cell.get_attribute('headers')
            headers_ids.each do |header_id|
              headers = Hatemile::Util::CommonFunctions.increase_in_list(
                headers,
                header_id
              )
            end
            cell.set_attribute('headers', headers)
          end
        end
      end

      ##
      # Fix the table header.
      #
      # @param table_header [Hatemile::Util::Html::HTMLDOMElement] The table
      #   header.
      # @return [void]
      def fix_header(table_header)
        cells = @parser.find(table_header).find_children('tr').find_children(
          'th'
        ).list_results
        cells.each do |cell|
          next unless Hatemile::Util::CommonFunctions.is_valid_element?(cell)

          @id_generator.generate_id(cell)
          cell.set_attribute('scope', 'col')
        end
      end

      public

      ##
      # Initializes a new object that improve the accessibility of associations
      # of parser.
      #
      # @param parser [Hatemile::Util::Html::HTMLDOMParser] The HTML parser.
      def initialize(parser)
        @parser = parser
        @id_generator = Hatemile::Util::IDGenerator.new('association')
      end

      ##
      # @see Hatemile::AccessibleAssociation#associate_data_cells_with_header_cells
      def associate_data_cells_with_header_cells(table)
        header = @parser.find(table).find_children('thead').first_result
        body = @parser.find(table).find_children('tbody').first_result
        footer = @parser.find(table).find_children('tfoot').first_result
        unless header.nil?
          fix_header(header)

          header_cells = generate_part(header)
          if !body.nil? && valid_header?(header_cells)
            length_header = header_cells[0].size
            fake_table = generate_part(body)
            unless footer.nil?
              fake_table = fake_table.concat(generate_part(footer))
            end
            fake_table.each do |cells|
              next unless cells.size == length_header

              cells.each_with_index do |cell, index|
                unless Hatemile::Util::CommonFunctions.is_valid_element?(cell)
                  next
                end

                headers_ids = return_list_ids_columns(header_cells, index)
                headers = cell.get_attribute('headers')
                headers_ids.each do |headers_id|
                  headers = Hatemile::Util::CommonFunctions.increase_in_list(
                    headers,
                    headers_id
                  )
                end
                cell.set_attribute('headers', headers)
              end
            end
          end
        end
        fix_body_or_footer(body) unless body.nil?
        fix_body_or_footer(footer) unless footer.nil?
      end

      ##
      # @see Hatemile::AccessibleAssociation#associate_all_data_cells_with_header_cells
      def associate_all_data_cells_with_header_cells
        tables = @parser.find('table').list_results
        tables.each do |table|
          if Hatemile::Util::CommonFunctions.is_valid_element?(table)
            associate_data_cells_with_header_cells(table)
          end
        end
      end

      ##
      # @see Hatemile::AccessibleAssociation#associate_label_with_field
      def associate_label_with_field(label)
        return unless label.get_tag_name == 'LABEL'

        if label.has_attribute?('for')
          field = @parser.find("##{label.get_attribute('for')}").first_result
        else
          field = @parser.find(label).find_descendants(
            'input,select,textarea'
          ).first_result

          unless field.nil? ||
                 !Hatemile::Util::CommonFunctions.is_valid_element?(field)
            @id_generator.generate_id(field)
            label.set_attribute('for', field.get_attribute('id'))
          end
        end

        return if field.nil?
        return unless Hatemile::Util::CommonFunctions.is_valid_element?(field)

        unless field.has_attribute?('aria-label')
          field.set_attribute(
            'aria-label',
            label.get_text_content.gsub(/[ \n\r\t]+/, ' ').strip
          )
        end

        @id_generator.generate_id(label)
        field.set_attribute(
          'aria-labelledby',
          Hatemile::Util::CommonFunctions.increase_in_list(
            field.get_attribute('aria-labelledby'),
            label.get_attribute('id')
          )
        )
      end

      ##
      # @see Hatemile::AccessibleAssociation#associate_all_labels_with_fields
      def associate_all_labels_with_fields
        labels = @parser.find('label').list_results
        labels.each do |label|
          if Hatemile::Util::CommonFunctions.is_valid_element?(label)
            associate_label_with_field(label)
          end
        end
      end
    end
  end
end
