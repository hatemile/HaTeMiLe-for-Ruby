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

require File.dirname(__FILE__) + '/../accessible_event.rb'
require File.dirname(__FILE__) + '/../util/common_functions.rb'

module Hatemile
  module Implementation
    ##
    # The AccessibleEventImplementation class is official implementation of
    # AccessibleEvent interface.
    class AccessibleEventImplementation < AccessibleEvent
      public_class_method :new

      protected

      ##
      # Provide keyboard access for element, if it not has.
      #
      # @param element [Hatemile::Util::HTMLDOMElement] The element.
      # @return [void]
      def keyboard_access(element)
        return if element.has_attribute?('tabindex')

        tag = element.get_tag_name
        if (tag == 'A') && !element.has_attribute?('href')
          element.set_attribute('tabindex', '0')
        elsif (tag != 'A') && (tag != 'INPUT') && (tag != 'BUTTON') && (tag != 'SELECT') && (tag != 'TEXTAREA')
          element.set_attribute('tabindex', '0')
        end
      end

      ##
      # Include the scripts used by solutions.
      #
      # @return [void]
      def generate_main_scripts
        head = @parser.find('head').first_result
        if !head.nil? && @parser.find("##{@id_script_event_listener}").first_result.nil?
          script = @parser.create_element('script')
          script.set_attribute('id', @id_script_event_listener)
          script.set_attribute('type', 'text/javascript')
          script.append_text(File.read(File.dirname(__FILE__) + '/../../js/eventlistener.js'))
          if head.has_children?
            head.get_first_element_child.insert_before(script)
          else
            head.append_element(script)
          end
        end
        local = @parser.find('body').first_result
        unless local.nil?
          @script_list = @parser.find("##{@id_list_ids_script}").first_result
          if @script_list.nil?
            @script_list = @parser.create_element('script')
            @script_list.set_attribute('id', @id_list_ids_script)
            @script_list.set_attribute('type', 'text/javascript')
            @script_list.append_text('var activeElements = [];')
            @script_list.append_text('var hoverElements = [];')
            @script_list.append_text('var dragElements = [];')
            @script_list.append_text('var dropElements = [];')
            local.append_element(@script_list)
          end
          if @parser.find("##{@id_function_script_fix}").first_result.nil?
            script_function = @parser.create_element('script')
            script_function.set_attribute('id', @id_function_script_fix)
            script_function.set_attribute('type', 'text/javascript')
            script_function.append_text(File.read(File.dirname(__FILE__) + '/../../js/include.js'))
            local.append_element(script_function)
          end
        end
        @main_script_added = true
      end

      ##
      # Add a type of event in element.
      #
      # @param element [Hatemile::Util::HTMLDOMElement] The element.
      # @param event [String] The type of event.
      # @return [void]
      def add_event_in_element(element, event)
        generate_main_scripts unless @main_script_added

        return if @script_list.nil?

        Hatemile::Util::CommonFunctions.generate_id(element, @prefix_id)
        @script_list.append_text("#{event}Elements.push('#{element.get_attribute('id')}');")
      end

      public

      ##
      # Initializes a new object that manipulate the accessibility of the
      # Javascript events of elements of parser.
      #
      # @param parser [Hatemile::Util::HTMLDOMParser] The HTML parser.
      # @param configure [Hatemile::Util::Configure] The configuration of
      #   HaTeMiLe.
      def initialize(parser, configure)
        @parser = parser
        @prefix_id = configure.get_parameter('prefix-generated-ids')
        @id_script_event_listener = 'script-eventlistener'
        @id_list_ids_script = 'list-ids-script'
        @id_function_script_fix = 'id-function-script-fix'
        @data_ignore = 'data-ignoreaccessibilityfix'
        @main_script_added = false
        @script_list = nil
      end

      def fix_drop(element)
        element.set_attribute('aria-dropeffect', 'none')

        add_event_in_element(element, 'drop')
      end

      def fix_drag(element)
        keyboard_access(element)

        element.set_attribute('aria-grabbed', 'false')

        add_event_in_element(element, 'drag')
      end

      def fix_drags_and_drops
        draggable_elements = @parser.find('[ondrag],[ondragstart],[ondragend]').list_results
        draggable_elements.each do |draggable_element|
          unless draggable_element.has_attribute?(@data_ignore)
            fix_drag(draggable_element)
          end
        end
        droppable_elements = @parser.find('[ondrop],[ondragenter],[ondragleave],[ondragover]').list_results
        droppable_elements.each do |droppable_element|
          unless droppable_element.has_attribute?(@data_ignore)
            fix_drop(droppable_element)
          end
        end
      end

      def fix_hover(element)
        keyboard_access(element)

        add_event_in_element(element, 'hover')
      end

      def fix_hovers
        elements = @parser.find('[onmouseover],[onmouseout]').list_results
        elements.each do |element|
          fix_hover(element) unless element.has_attribute?(@data_ignore)
        end
      end

      def fix_active(element)
        keyboard_access(element)

        add_event_in_element(element, 'active')
      end

      def fix_actives
        elements = @parser.find('[onclick],[onmousedown],[onmouseup],[ondblclick]').list_results
        elements.each do |element|
          fix_active(element) unless element.has_attribute?(@data_ignore)
        end
      end
    end
  end
end
