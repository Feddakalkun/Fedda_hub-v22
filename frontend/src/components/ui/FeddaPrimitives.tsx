import type { ButtonHTMLAttributes, ReactNode } from 'react';

type FeddaButtonVariant = 'ghost' | 'violet' | 'cyan' | 'emerald';

interface FeddaButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: FeddaButtonVariant;
  children: ReactNode;
}

const variantClassMap: Record<FeddaButtonVariant, string> = {
  ghost: 'fedda-btn-ghost',
  violet: 'border border-white/15 bg-white/[0.055] text-zinc-200 hover:border-white/25 hover:bg-white/[0.09]',
  cyan: 'fedda-btn-soft-cyan',
  emerald: 'fedda-btn-soft-emerald',
};

export const FeddaButton = ({
  variant = 'ghost',
  className = '',
  disabled,
  children,
  ...props
}: FeddaButtonProps) => {
  return (
    <button
      {...props}
      disabled={disabled}
      className={`${variantClassMap[variant]} ${disabled ? 'opacity-50 cursor-not-allowed' : ''} ${className}`.trim()}
    >
      {children}
    </button>
  );
};

interface FeddaPanelProps {
  className?: string;
  children: ReactNode;
}

export const FeddaPanel = ({ className = '', children }: FeddaPanelProps) => {
  return <div className={`fedda-surface-panel ${className}`.trim()}>{children}</div>;
};

interface FeddaSectionTitleProps {
  children: ReactNode;
  className?: string;
}

export const FeddaSectionTitle = ({ children, className = '' }: FeddaSectionTitleProps) => {
  return <p className={`fedda-kicker ${className}`.trim()}>{children}</p>;
};
