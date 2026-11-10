interface Props {
  title: string;
  lead: string;
}

/** Заголовок раздела. Содержимое разделов приходит тикетами W-02…W-08. */
export function SectionPage({ title, lead }: Props) {
  return (
    <section className="page">
      <h1 className="page__title">{title}</h1>
      <p className="muted">{lead}</p>
    </section>
  );
}
