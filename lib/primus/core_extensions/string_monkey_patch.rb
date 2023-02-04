module Primus
  module CoreExtensions
    module StringMonkeyPatch
      class << self
        def apply_patch
          const = find_const

          if const
            const.prepend(self)
          end
        end

        private

        def find_const
          Kernel.const_get("::String")
        rescue NameError
        end
      end

      def gp_sum
        Primus.sum(self)
      end
    end
  end
end
