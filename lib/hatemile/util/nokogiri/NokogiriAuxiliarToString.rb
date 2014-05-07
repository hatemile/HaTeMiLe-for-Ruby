#Copyright 2014 Carlson Santana Cruz
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.
module Hatemile
	module Util
		module NokogiriLib
			class NokogiriAuxiliarToString
				@@self_closing_tags = ['area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'keygen', 'link', 'menuitem', 'meta', 'param', 'source', 'track', 'wbr']
				private_class_method :new
				def self.toString(node)
					string = ''
					if node.element?
						string += "<#{node.name.downcase()}"
						node.attributes.each() do |attribute, value|
							string += " #{attribute}=\"#{value}\""
						end
						if node.children.empty? and self.self_closing_tag?(node.name)
							string += ' />'
						else
							string += '>'
						end
					elsif node.comment?
						string += node.to_s()
					elsif node.cdata?
						string += node.to_s()
					elsif node.html?
						document = node.to_s()
						string += document.split("\n")[0] + "\n"
					elsif node.text?
						string += node.text()
					end
					
					node.children.each() do |child|
						string += self.toString(child)
					end
					
					if node.element? and not (node.children.empty? and self.self_closing_tag?(node.name))
						string += "</#{node.name.downcase()}>"
					end
					return string
				end
				def self.self_closing_tag?(tag)
					return @@self_closing_tags.include?(tag.downcase())
				end
			end
		end
	end
end