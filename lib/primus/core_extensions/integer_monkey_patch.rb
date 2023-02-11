module Primus
  module CoreExtensions
    module IntegerMonkeyPatch
      class << self
        def apply_patch
          const = find_const

          if const
            const.prepend(self)
          end
        end

        private

        def find_const
          Kernel.const_get("::Integer")
        rescue NameError
        end
      end

      def emirp?
        to_s.reverse.to_i.prime?
      end
    end
  end
end
