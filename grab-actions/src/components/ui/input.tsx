import * as React from "react"
import { cn } from "../../lib/utils"

export interface InputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, ...props }, ref) => {
    return (
      <input
        type={type}
        className={cn(
          "flex h-9 w-full rounded-md border border-white/[0.04] bg-white/[0.03] backdrop-blur-xl px-3 py-1 text-sm text-white placeholder:text-white/25 focus:border-white/[0.08] focus:ring-1 focus:ring-white/[0.04] focus:outline-none disabled:cursor-not-allowed disabled:opacity-50 transition-all duration-150 font-mono font-thin",
          className
        )}
        ref={ref}
        {...props}
      />
    )
  }
)
Input.displayName = "Input"

export { Input }