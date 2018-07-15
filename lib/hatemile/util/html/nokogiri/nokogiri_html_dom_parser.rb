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

require 'nokogiri'
require File.join(File.dirname(File.dirname(__FILE__)), 'html_dom_parser')
require File.join(File.dirname(__FILE__), 'nokogiri_html_dom_element')

##
# The Hatemile module contains the interfaces with the acessibility solutions.
module Hatemile
  ##
  # The Hatemile::Util module contains the utilities of library.
  module Util
    ##
    # The Hatemile::Util::Html module contains the interfaces of HTML handles.
    module Html
      ##
      # The Hatemile::Util::NokogiriLib module contains the implementation of
      # HTML handles for Nokogiri library.
      module NokogiriLib
        ##
        # The class NokogiriHTMLDOMParser is official implementation of
        # HTMLDOMParser interface for the Nokogiri library.
        class NokogiriHTMLDOMParser < Hatemile::Util::Html::HTMLDOMParser
          public_class_method :new

          protected

          ##
          # Order the results.
          #
          # @param results [Array<Nokogiri::XML::Node>] The disordened results.
          # @return [Array<Nokogiri::XML::Node>] The ordened results.
          def order_results(results)
            parents = []
            groups = []
            results.each do |result|
              if parents.include?(result.parent)
                groups[parents.index(result.parent)].push(result)
              else
                parents.push(result.parent)
                groups.push([])
                groups[groups.size - 1].push(result)
              end
            end
            array = []
            groups.each do |group|
              col = group.sort do |element1, element2|
                children = element1.parent.children
                children.index(element1) <=> children.index(element2)
              end
              array = array.concat(col)
            end
            array
          end

          public

          ##
          # Initializes a new object that encapsulate the parser of Jsoup.
          #
          # @param code_or_parser [String, Nokogiri::HTML::Document] The HTML
          #   code or the parser of Nokogiri.
          # @param encoding [String] The enconding of code.
          def initialize(code_or_parser, encoding = 'UTF-8')
            @document = if code_or_parser.class == String
                          Nokogiri::HTML::Document.parse(
                            code_or_parser,
                            nil,
                            encoding
                          )
                        else
                          code_or_parser
                        end
            @results = nil
          end

          ##
          # @see Hatemile::Util::Html::HTMLDOMParser#find
          def find(selector)
            @results = if selector.class == NokogiriHTMLDOMElement
                         [selector.get_data]
                       else
                         @document.css(selector)
                       end
            self
          end

          ##
          # @see Hatemile::Util::Html::HTMLDOMParser#find_children
          def find_children(selector)
            array = []
            if selector.class == NokogiriHTMLDOMElement
              element = selector.get_data
              @results.each do |result|
                if result.children.include?(element)
                  array.push(element)
                  break
                end
              end
            else
              @results.each do |result|
                result.css(selector).each do |found_element|
                  array.push(found_element) if found_element.parent == result
                end
              end
            end
            @results = array
            self
          end

          ##
          # @see Hatemile::Util::Html::HTMLDOMParser#find_descendants
          def find_descendants(selector)
            array = []
            if selector.class == NokogiriHTMLDOMElement
              element = selector.get_data
              parents = element.ancestors
              @results.each do |result|
                if parents.include?(result)
                  array.push(element)
                  break
                end
              end
            else
              @results.each do |result|
                array = array.concat(result.css(selector))
              end
            end
            @results = array
            self
          end

          ##
          # @see Hatemile::Util::Html::HTMLDOMParser#find_ancestors
          def find_ancestors(selector)
            array = []
            if selector.class == NokogiriHTMLDOMElement
              element = selector.get_data
              @results.each do |result|
                parents = result.ancestors
                if parents.include?(element)
                  array.push(element)
                  break
                end
              end
            else
              @results.each do |result|
                array = array.concat(result.ancestors(selector))
              end
            end
            @results = array
            self
          end

          ##
          # @see Hatemile::Util::Html::HTMLDOMParser#first_result
          def first_result
            return nil if @results.nil? || @results.empty?
            NokogiriHTMLDOMElement.new(@results[0])
          end

          ##
          # @see Hatemile::Util::Html::HTMLDOMParser#last_result
          def last_result
            return nil if @results.nil? || @results.empty?
            NokogiriHTMLDOMElement.new(@results[@results.length - 1])
          end

          ##
          # @see Hatemile::Util::Html::HTMLDOMParser#list_results
          def list_results
            array = []
            order_results(@results).each do |result|
              array.push(NokogiriHTMLDOMElement.new(result))
            end
            array
          end

          ##
          # @see Hatemile::Util::Html::HTMLDOMParser#create_element
          def create_element(tag)
            NokogiriHTMLDOMElement.new(@document.create_element(tag))
          end

          ##
          # @see Hatemile::Util::Html::HTMLDOMParser#get_html
          def get_html
            NokogiriHTMLDOMElement.new(@document).get_outer_html
          end

          ##
          # @see Hatemile::Util::Html::HTMLDOMParser#get_parser
          def get_parser
            @document
          end

          ##
          # @see Hatemile::Util::Html::HTMLDOMParser#clear_parser
          def clear_parser
            @document = nil
            @results.clear
            @results = nil
          end
        end
      end
    end
  end
end
