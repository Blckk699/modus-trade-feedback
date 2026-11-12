import { useState } from "react";
import { Link } from "react-router-dom";
import { api, unwrap } from "../api/client";
import { ApiError, errorMessage } from "../api/errors";
import type { Schemas } from "../api/types";
import { useBackground } from "../app/background";
import { Confirm } from "../app/Confirm";
import { useDictionaries } from "../app/dictionaries";
import { useAsync } from "../lib/useAsync";
import { mergeBlockReason } from "./mergeReason";
import { StatusBadge } from "./Badges";

type Appeal = Schemas["Appeal"];
type Suggestion = Schemas["DuplicateSuggestion"];

interface Props {
  appeal: Appeal;
  /** После склейки — перечитать карточку: повтор становится «Закрыто» со ссылкой на основное. */
  onMerged: (main: Appeal) => void;
}

/**
 * Подсказки о похожих обращениях (истории 34–36). Бэкенд сам решает, кому их показывать
 * (автору — пустой список), и можно ли склеить сейчас (can_merge).
 */
export function DuplicatesSection({ appeal, onMerged }: Props) {
  const list = useAsync(
    () =>
      unwrap(
        api.GET("/api/v1/appeals/{appeal_id}/similar", {
          params: { path: { appeal_id: appeal.id } },
        }),
      ),
    [appeal.id, appeal.updated_at],
  );
  const background = useBackground();
  const dict = useDictionaries();
  const [busy, setBusy] = useState<number | null>(null);
  const [error, setError] = useState("");
  /** Склейку не отменить — перед ней спрашиваем. */
  const [asking, setAsking] = useState<Suggestion | null>(null);

  if (
    list.state.status === "error" &&
    list.state.error instanceof ApiError &&
    list.state.error.status === 403
  )
    return null;
  if (list.state.status !== "ready" && list.state.status !== "error")
    return null;
  if (list.state.status === "ready" && list.state.data.length === 0)
    return null;

  const canMerge = appeal.allowed_actions.includes("merge");

  async function merge(s: Suggestion) {
    setBusy(s.id);
    setError("");
    try {
      const main = await unwrap(
        api.POST("/api/v1/appeals/{appeal_id}/merge", {
          params: { path: { appeal_id: appeal.id } },
          body: { main_appeal_id: s.similar_appeal.id },
        }),
      );
      setAsking(null);
      onMerged(main);
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy(null);
    }
  }

  async function dismiss(s: Suggestion) {
    setBusy(s.id);
    setError("");
    try {
      await unwrap(
        api.POST("/api/v1/duplicate-suggestions/{suggestion_id}/dismiss", {
          params: { path: { suggestion_id: s.id } },
        }),
      );
      if (list.state.status === "ready")
        list.set(list.state.data.filter((x) => x.id !== s.id));
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy(null);
    }
  }

  return (
    <section className="section">
      <h2 className="section__title">Похожие обращения</h2>
      {list.state.status === "error" && (
        <p className="error-text">{list.state.message}</p>
      )}
      {list.state.status === "ready" && (
        <ul className="suggestions">
          {list.state.data.map((s) => {
            const blocked = mergeBlockReason({
              status: appeal.status,
              canMergeHere: canMerge,
              main: {
                number: s.similar_appeal.number,
                status: s.similar_appeal.status,
              },
              canMergeSuggestion: s.can_merge,
              statusLabel: dict.statusLabel,
            });
            return (
              <li key={s.id} className="suggestion">
                <div className="suggestion__head">
                  <Link
                    to={`/appeals/${s.similar_appeal.id}`}
                    state={{ background }}
                    className="suggestion__link"
                  >
                    <span className="muted">{s.similar_appeal.number}</span>{" "}
                    {s.similar_appeal.summary ?? "Без краткой сути"}
                  </Link>
                  <StatusBadge status={s.similar_appeal.status} />
                </div>
                <p className="muted suggestion__why">{s.explanation}</p>
                <div className="form__actions">
                  <button
                    type="button"
                    className="btn btn--sm"
                    disabled={busy !== null || blocked !== null}
                    aria-describedby={blocked ? `merge-why-${s.id}` : undefined}
                    onClick={() => (setError(""), setAsking(s))}
                  >
                    Присоединить к {s.similar_appeal.number}
                  </button>
                  <button
                    type="button"
                    className="btn btn--soft btn--sm"
                    disabled={busy !== null}
                    onClick={() => dismiss(s)}
                  >
                    Это другое
                  </button>
                </div>
                {blocked && (
                  <p id={`merge-why-${s.id}`} className="suggestion__blocked">
                    {blocked}
                  </p>
                )}
              </li>
            );
          })}
        </ul>
      )}
      <Confirm
        open={asking !== null}
        title={
          asking
            ? `Присоединить ${appeal.number} к ${asking.similar_appeal.number}?`
            : ""
        }
        confirmLabel="Присоединить"
        busyLabel="Присоединяем…"
        busy={busy !== null}
        error={error}
        onConfirm={() => asking && void merge(asking)}
        onCancel={() => setAsking(null)}
      >
        <p>
          {appeal.number} закроется как повтор со ссылкой на{" "}
          {asking?.similar_appeal.number}. Его автор станет участником основного
          обращения и будет получать его статусы, но не увидит чужой текст и
          имя.
        </p>
        <p>Отменить склейку нельзя.</p>
      </Confirm>
      {error && (
        <p className="error-text" role="alert">
          {error}
        </p>
      )}
    </section>
  );
}
