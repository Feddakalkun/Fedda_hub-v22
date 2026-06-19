import { useModules } from '../../contexts/ModuleContext';

interface RichHomeProps {
  onSelect: (id: string) => void;
}

export const RichHome = ({ onSelect }: RichHomeProps) => {
  const { availableModules } = useModules();
  const cards = availableModules.filter((module) => module.card && (module.area === 'home' || module.area === 'system'));
  const topCards = cards.slice(0, 2);
  const bottomCards = cards.slice(2);

  return (
    <div className="h-full overflow-y-auto custom-scrollbar bg-[#050506]">
      <div className="mx-auto flex min-h-full w-full max-w-[1500px] flex-col px-8 py-8 pt-4">
        <section className="space-y-4">
          <div className="mx-auto grid max-w-[980px] gap-4 md:grid-cols-2">
            {topCards.map((module) => (
              <button
                key={module.id}
                onClick={() => onSelect(module.defaultTab)}
                aria-label={module.label}
                className="group relative aspect-[1168/784] overflow-hidden rounded-lg border border-white/10 bg-[#08090d] transition-all hover:-translate-y-0.5 hover:border-white/25"
              >
                {module.card?.poster ? (
                  <>
                    <img
                      src={module.card.poster}
                      alt=""
                      className="absolute inset-0 h-full w-full object-cover transition duration-500 group-hover:scale-[1.03]"
                    />
                    {module.card?.video ? (
                      <video
                        className="absolute inset-0 h-full w-full object-cover opacity-0 transition duration-500 group-hover:scale-[1.03] group-hover:opacity-100"
                        src={module.card.video}
                        poster={module.card.poster}
                        muted
                        loop
                        playsInline
                        autoPlay
                      />
                    ) : null}
                  </>
                ) : null}
              </button>
            ))}
          </div>

          <div className="mx-auto grid max-w-[980px] gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {bottomCards.map((module) => (
              <button
                key={module.id}
                onClick={() => onSelect(module.defaultTab)}
                aria-label={module.label}
                className="group relative aspect-[1168/784] overflow-hidden rounded-lg border border-white/10 bg-[#08090d] transition-all hover:-translate-y-0.5 hover:border-white/25"
              >
                {module.card?.poster ? (
                  <>
                    <img
                      src={module.card.poster}
                      alt=""
                      className="absolute inset-0 h-full w-full object-cover transition duration-500 group-hover:scale-[1.03]"
                    />
                    {module.card?.video ? (
                      <video
                        className="absolute inset-0 h-full w-full object-cover opacity-0 transition duration-500 group-hover:scale-[1.03] group-hover:opacity-100"
                        src={module.card.video}
                        poster={module.card.poster}
                        muted
                        loop
                        playsInline
                        autoPlay
                      />
                    ) : null}
                  </>
                ) : null}
              </button>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
};