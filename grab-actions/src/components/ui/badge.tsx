import * as React from "react"
import { cn } from "../../lib/utils"

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement> {}

function Badge({ className, ...props }: BadgeProps) {
  return (
    <div
      className={cn(
        "inline-flex items-center rounded-md border px-2.5 py-0.5 text-xs font-mono font-thin transition-colors focus:outline-none focus:ring-2 focus:ring-white/20 focus:ring-offset-2",
        "bg-white/[0.03] text-white/50 border-white/[0.06]",
        className
      )}
      {...props}
    />
  )
}

export { Badge }