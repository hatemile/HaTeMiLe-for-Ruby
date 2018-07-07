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

      ##
      # The content of eventlistener.js.
      @@eventListenerScriptContent = nil

      ##
      # The content of include.js.
      @@includeScriptContent = nil

      protected

      ##
      # Provide keyboard access for element, if it not has.
      #
      # ---
      #
      # Parameters:
      #  1. Hatemile::Util::HTMLDOMElement +element+ The element.
      def keyboardAccess(element)
        return if element.hasAttribute?('tabindex')

        tag = element.getTagName
        if (tag == 'A') && !element.hasAttribute?('href')
          element.setAttribute('tabindex', '0')
        elsif (tag != 'A') && (tag != 'INPUT') && (tag != 'BUTTON') && (tag != 'SELECT') && (tag != 'TEXTAREA')
          element.setAttribute('tabindex', '0')
        end
      end

      ##
      # Include the scripts used by solutions.
      def generateMainScripts
        head = @parser.find('head').firstResult
        if !head.nil? && @parser.find("##{@idScriptEventListener}").firstResult.nil?
          if @storeScriptsContent
            if @@eventListenerScriptContent.nil?
              @@eventListenerScriptContent = File.read(File.dirname(__FILE__) + '/../../js/eventlistener.js')
            end
            localEventListenerScriptContent = @@eventListenerScriptContent
          else
            localEventListenerScriptContent = File.read(File.dirname(__FILE__) + '/../../js/eventlistener.js')
          end

          script = @parser.createElement('script')
          script.setAttribute('id', @idScriptEventListener)
          script.setAttribute('type', 'text/javascript')
          script.appendText(localEventListenerScriptContent)
          if head.hasChildren?
            head.getFirstElementChild.insertBefore(script)
          else
            head.appendElement(script)
          end
        end
        local = @parser.find('body').firstResult
        unless local.nil?
          @scriptList = @parser.find("##{@idListIdsScript}").firstResult
          if @scriptList.nil?
            @scriptList = @parser.createElement('script')
            @scriptList.setAttribute('id', @idListIdsScript)
            @scriptList.setAttribute('type', 'text/javascript')
            @scriptList.appendText('var activeElements = [];')
            @scriptList.appendText('var hoverElements = [];')
            @scriptList.appendText('var dragElements = [];')
            @scriptList.appendText('var dropElements = [];')
            local.appendElement(@scriptList)
          end
          if @parser.find("##{@idFunctionScriptFix}").firstResult.nil?
            if @storeScriptsContent
              if @@includeScriptContent.nil?
                @@includeScriptContent = File.read(File.dirname(__FILE__) + '/../../js/include.js')
              end
              localIncludeScriptContent = @@includeScriptContent
            else
              localIncludeScriptContent = File.read(File.dirname(__FILE__) + '/../../js/include.js')
            end

            scriptFunction = @parser.createElement('script')
            scriptFunction.setAttribute('id', @idFunctionScriptFix)
            scriptFunction.setAttribute('type', 'text/javascript')
            scriptFunction.appendText(localIncludeScriptContent)
            local.appendElement(scriptFunction)
          end
        end
        @mainScriptAdded = true
      end

      ##
      # Add a type of event in element.
      #
      # ---
      #
      # Parameters:
      #  1. Hatemile::Util::HTMLDOMElement +element+ The element.
      #  2. String +event+ The type of event.
      def addEventInElement(element, event)
        generateMainScripts unless @mainScriptAdded

        return if @scriptList.nil?

        Hatemile::Util::CommonFunctions.generateId(element, @prefixId)
        @scriptList.appendText("#{event}Elements.push('#{element.getAttribute('id')}');")
      end

      public

      ##
      # Initializes a new object that manipulate the accessibility of the
      # Javascript events of elements of parser.
      #
      # ---
      #
      # Parameters:
      #  1. Hatemile::Util::HTMLDOMParser +parser+ The HTML parser.
      #  2. Hatemile::Util::Configure +configure+ The configuration of HaTeMiLe.
      #  3. Boolean +storeScriptsContent+ The state that indicates if the
      #  scripts used are stored or deleted, after use.
      def initialize(parser, configure, storeScriptsContent)
        @parser = parser
        @storeScriptsContent = storeScriptsContent
        @prefixId = configure.getParameter('prefix-generated-ids')
        @idScriptEventListener = 'script-eventlistener'
        @idListIdsScript = 'list-ids-script'
        @idFunctionScriptFix = 'id-function-script-fix'
        @dataIgnore = 'data-ignoreaccessibilityfix'
        @mainScriptAdded = false
        @scriptList = nil
      end

      def fixDrop(element)
        element.setAttribute('aria-dropeffect', 'none')

        addEventInElement(element, 'drop')
      end

      def fixDrag(element)
        keyboardAccess(element)

        element.setAttribute('aria-grabbed', 'false')

        addEventInElement(element, 'drag')
      end

      def fixDragsandDrops
        draggableElements = @parser.find('[ondrag],[ondragstart],[ondragend]').listResults
        draggableElements.each do |draggableElement|
          unless draggableElement.hasAttribute?(@dataIgnore)
            fixDrag(draggableElement)
          end
        end
        droppableElements = @parser.find('[ondrop],[ondragenter],[ondragleave],[ondragover]').listResults
        droppableElements.each do |droppableElement|
          unless droppableElement.hasAttribute?(@dataIgnore)
            fixDrop(droppableElement)
          end
        end
      end

      def fixHover(element)
        keyboardAccess(element)

        addEventInElement(element, 'hover')
      end

      def fixHovers
        elements = @parser.find('[onmouseover],[onmouseout]').listResults
        elements.each do |element|
          fixHover(element) unless element.hasAttribute?(@dataIgnore)
        end
      end

      def fixActive(element)
        keyboardAccess(element)

        addEventInElement(element, 'active')
      end

      def fixActives
        elements = @parser.find('[onclick],[onmousedown],[onmouseup],[ondblclick]').listResults
        elements.each do |element|
          fixActive(element) unless element.hasAttribute?(@dataIgnore)
        end
      end
    end
  end
end
