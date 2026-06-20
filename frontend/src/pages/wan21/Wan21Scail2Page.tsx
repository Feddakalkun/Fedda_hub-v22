import { useEffect, useRef, useState } from 'react';
import type { ReactNode } from 'react';
import { Download, ExternalLink, Film, Loader2, Play, Upload, Video } from 'lucide-react';
import { BACKEND_API } from '../../config/api';
import { useToast } from '../../components/ui/Toast';
import { useComfyExecution } from '../../contexts/ComfyExecutionContext';
import { usePersistentState } from '../../hooks/usePersistentState';
import { comfyService } from '../../services/comfyService';
import { WorkflowShell } from '../../components/layout/WorkflowShell';
import { triggerMediaDownload } from '../../utils/mediaStore';

const inputBase =
  'w-full rounded-lg border border-white/10 bg-black/35 px-3 py-2 text-sm text-zinc-100 outline-none transition focus:border-white/25 placeholder:text-zinc-600';
const smallLabel = 'text-[10px] font-semibold uppercase tracking-[0.16em] text-zinc-500';
const panel = 'rounded-xl border border-white/10 bg-[#09090b] p-4 shadow-[0_0_0_1px_rgba(255,255,255,0.02)]';

function isScail2Url(url: string) {
  return /(scail2|scail-2|SCAIL2|video%2fscail|video\/scail)/i.test(url);
}

function classNames(...items: Array<string | false | null | undefined>) {
  return items.filter(Boolean).join(' ');
}

const Field = ({
  label,
  children,
  className = '',
}: {
  label: string;
  children: ReactNode;
  className?: string;
}) => (
  <div className={classNames('space-y-1.5', className)}>
    <span className={smallLabel}>{label}</span>
    {children}
  </div>
);

const NeutralButton = ({
  children,
  onClick,
  disabled,
  className = '',
}: {
  children: ReactNode;
  onClick?: () => void;
  disabled?: boolean;
  className?: string;
}) => (
  <button
    type="button"
    onClick={onClick}
    disabled={disabled}
    className={classNames(
      'inline-flex items-center justify-center gap-2 rounded-lg border border-white/10 bg-white/[0.04] px-3 py-2 text-xs font-semibold text-zinc-200 transition hover:bg-white/[0.08] disabled:cursor-not-allowed disabled:opacity-40',
      className,
    )}
  >
    {children}
  </button>
);

const UploadDrop = ({
  accept,
  label,
  filename,
  preview,
  busy,
  onFile,
}: {
  accept: string;
  label: string;
  filename: string | null;
  preview?: ReactNode;
  busy: boolean;
  onFile: (file: File) => void;
}) => {
  const inputRef = useRef<HTMLInputElement>(null);
  return (
    <div className="space-y-2">
      <button
        type="button"
        onClick={() => inputRef.current?.click()}
        className="flex min-h-[92px] w-full items-center justify-center rounded-xl border border-dashed border-white/15 bg-black/30 px-4 py-4 text-center transition hover:border-white/30 hover:bg-white/[0.03]"
      >
        {busy ? (
          <span className="inline-flex items-center gap-2 text-sm text-zinc-400">
            <Loader2 className="h-4 w-4 animate-spin" />
            Uploading
          </span>
        ) : preview ? (
          preview
        ) : (
          <span className="inline-flex items-center gap-2 text-sm text-zinc-400">
            <Upload className="h-4 w-4" />
            {label}
          </span>
        )}
      </button>
      <input
        ref={inputRef}
        type="file"
        accept={accept}
        className="hidden"
        onChange={(event) => {
          const file = event.target.files?.[0];
          if (file) onFile(file);
          event.currentTarget.value = '';
        }}
      />
      {filename ? <p className="truncate text-[11px] text-zinc-500">{filename}</p> : null}
    </div>
  );
};

const VideoPreviewStrip = ({
  currentVideo,
  history,
  isGenerating,
  onSelectVideo,
  downloadName,
}: {
  currentVideo: string | null;
  history: string[];
  isGenerating: boolean;
  onSelectVideo: (url: string) => void;
  downloadName: string;
}) => (
  <section className="rounded-xl border border-white/10 bg-[#09090b] p-3">
    <div className="mb-2 flex items-center justify-between gap-3">
      <button
        type="button"
        onClick={() => currentVideo && window.open(currentVideo, '_blank', 'noopener,noreferrer')}
        disabled={!currentVideo}
        className="inline-flex items-center gap-2 text-[10px] font-semibold uppercase tracking-[0.18em] text-zinc-500 transition hover:text-zinc-200 disabled:pointer-events-none"
      >
        <Video className="h-3.5 w-3.5" />
        Output Preview
      </button>
      <div className="flex items-center gap-2">
        <span className="text-[9px] font-mono text-zinc-600">
          {isGenerating ? 'Rendering' : 'Recent'} · {history.length}
        </span>
        {currentVideo ? (
          <>
            <button
              type="button"
              onClick={() => window.open(currentVideo, '_blank', 'noopener,noreferrer')}
              className="rounded-md border border-white/10 bg-white/[0.04] p-1.5 text-zinc-400 transition hover:text-zinc-100"
              title="Open output"
            >
              <ExternalLink className="h-3.5 w-3.5" />
            </button>
            <button
              type="button"
              onClick={() => triggerMediaDownload(currentVideo, downloadName)}
              className="rounded-md border border-white/10 bg-white/[0.04] p-1.5 text-zinc-400 transition hover:text-zinc-100"
              title="Download output"
            >
              <Download className="h-3.5 w-3.5" />
            </button>
          </>
        ) : null}
      </div>
    </div>
    <div className="flex gap-2 overflow-x-auto pb-1 custom-scrollbar">
      {currentVideo ? (
        <button
          type="button"
          onClick={() => onSelectVideo(currentVideo)}
          className="relative h-24 w-40 shrink-0 overflow-hidden rounded-lg border border-white/25 bg-black"
        >
          <video src={currentVideo} className="h-full w-full object-cover" muted playsInline />
          <div className="absolute left-1.5 top-1.5 rounded bg-zinc-100 px-1.5 py-0.5 text-[7px] font-bold uppercase tracking-wider text-black">
            Selected
          </div>
        </button>
      ) : (
        <div className="flex h-24 w-40 shrink-0 items-center justify-center rounded-lg border border-white/10 bg-black/35 text-center text-[11px] text-zinc-700">
          {isGenerating ? 'Rendering output' : 'No output yet'}
        </div>
      )}
      {history.filter((url) => url !== currentVideo).slice(0, 10).map((url, index) => (
        <button
          key={`${url}-${index}`}
          type="button"
          onClick={() => onSelectVideo(url)}
          className="h-24 w-40 shrink-0 overflow-hidden rounded-lg border border-white/10 bg-black transition hover:border-white/30"
        >
          <video src={url} className="h-full w-full object-cover" muted playsInline />
        </button>
      ))}
    </div>
  </section>
);

export function Wan21Scail2Page() {
  const { toast } = useToast();
  const {
    state: execState,
    error: execError,
    lastOutputVideos,
    outputReadyCount,
    registerNodeMap,
  } = useComfyExecution();

  const prevVideoCountRef = useRef(0);
  const sessionRef = useRef<string[]>([]);

  const [referenceImageFile, setReferenceImageFile] = usePersistentState<string | null>('scail2_ref_image', null);
  const [motionVideoFile, setMotionVideoFile] = usePersistentState<string | null>('scail2_motion_video', null);
  const [uploadingImage, setUploadingImage] = useState(false);
  const [uploadingVideo, setUploadingVideo] = useState(false);

  const [prompt, setPrompt] = usePersistentState('scail2_prompt', 'a person dancing, cinematic lighting, natural movement');
  const [negative, setNegative] = usePersistentState('scail2_negative', '');
  const [showNegative, setShowNegative] = useState(false);
  const [frameLength, setFrameLength] = usePersistentState('scail2_frames', 50);
  const [width, setWidth] = usePersistentState('scail2_width', 720);
  const [height, setHeight] = usePersistentState('scail2_height', 1200);
  const [seed, setSeed] = usePersistentState('scail2_seed', -1);

  const [currentVideo, setCurrentVideo] = useState<string | null>(null);
  const [history, setHistory] = usePersistentState<string[]>('scail2_history', []);
  const [isGenerating, setIsGenerating] = useState(false);
  const [pendingPromptId, setPendingPromptId] = useState<string | null>(null);

  const refImagePreviewUrl = referenceImageFile
    ? `/comfy/view?filename=${encodeURIComponent(referenceImageFile)}&subfolder=&type=input`
    : null;
  const motionPreviewUrl = motionVideoFile
    ? `/comfy/view?filename=${encodeURIComponent(motionVideoFile)}&subfolder=&type=input`
    : null;

  const canRun = !!referenceImageFile && !!motionVideoFile && !!prompt.trim() && !isGenerating;

  useEffect(() => {
    if (!isGenerating && !pendingPromptId) return;
    if (!lastOutputVideos?.length) return;
    const newVideos = lastOutputVideos.slice(prevVideoCountRef.current);
    if (newVideos.length === 0) return;
    prevVideoCountRef.current = lastOutputVideos.length;
    const urls = newVideos.map((v) => comfyService.getImageUrl(v));
    const preferred = urls.filter((url) => isScail2Url(url));
    const picked = preferred.length > 0 ? preferred : urls;
    if (picked.length === 0) return;
    sessionRef.current = [...sessionRef.current, ...picked];
    setCurrentVideo(picked[picked.length - 1]);
    setHistory((prev) => [...picked, ...prev].slice(0, 40));
  }, [outputReadyCount, lastOutputVideos, isGenerating, pendingPromptId, setHistory]);

  useEffect(() => {
    if (!pendingPromptId) return;
    if (execState === 'done') {
      setIsGenerating(false);
      setPendingPromptId(null);
      toast(`SCAIL-2 done (${sessionRef.current.length || 1} output)`, 'success');
    }
    if (execState === 'error') {
      setIsGenerating(false);
      setPendingPromptId(null);
      const message = typeof execError === 'string' ? execError : execError?.message || 'SCAIL-2 failed';
      toast(message, 'error');
    }
  }, [execError, execState, pendingPromptId, toast]);

  useEffect(() => {
    if (!pendingPromptId || !isGenerating) return;
    let cancelled = false;
    let attempts = 0;
    const maxAttempts = 360;

    const poll = async () => {
      if (cancelled) return;
      attempts += 1;
      try {
        const res = await fetch(`${BACKEND_API.BASE_URL}/api/generate/status/${encodeURIComponent(pendingPromptId)}`);
        const data = await res.json();
        if (!res.ok || !data.success) return;
        if (data.status === 'completed') {
          const videos = Array.isArray(data.videos) ? data.videos : [];
          const urls = videos.map((v: any) => comfyService.getImageUrl(v));
          const preferred = urls.filter((url: string) => isScail2Url(url));
          const picked = preferred.length > 0 ? preferred : urls;
          if (picked.length > 0) {
            sessionRef.current = [...sessionRef.current, ...picked];
            setCurrentVideo(picked[picked.length - 1]);
            setHistory((prev) => [...picked, ...prev].slice(0, 40));
            setIsGenerating(false);
            setPendingPromptId(null);
            toast(`SCAIL-2 done (${picked.length} output)`, 'success');
            return;
          }
          setIsGenerating(false);
          setPendingPromptId(null);
          toast('Run completed but no video detected.', 'error');
          return;
        }
      } catch {
        // keep polling on transient errors
      }
      if (!cancelled && attempts >= maxAttempts) {
        setIsGenerating(false);
        setPendingPromptId(null);
        toast('Timed out waiting for SCAIL-2 output.', 'error');
      }
    };

    const timer = window.setInterval(poll, 5000);
    void poll();
    return () => {
      cancelled = true;
      window.clearInterval(timer);
    };
  }, [isGenerating, pendingPromptId, setHistory, toast]);

  const uploadToComfy = async (file: File) => {
    const form = new FormData();
    form.append('file', file);
    const res = await fetch(`${BACKEND_API.BASE_URL}/api/upload`, { method: 'POST', body: form });
    const data = await res.json();
    if (!res.ok || !data.success) throw new Error(data.detail || 'Upload failed');
    return String(data.filename);
  };

  const handleImageUpload = async (file: File) => {
    setUploadingImage(true);
    try {
      const filename = await uploadToComfy(file);
      setReferenceImageFile(filename);
      toast('Reference image uploaded', 'success');
    } catch (err: any) {
      toast(err.message || 'Image upload failed', 'error');
    } finally {
      setUploadingImage(false);
    }
  };

  const handleVideoUpload = async (file: File) => {
    setUploadingVideo(true);
    try {
      const filename = await uploadToComfy(file);
      setMotionVideoFile(filename);
      toast('Motion video uploaded', 'success');
    } catch (err: any) {
      toast(err.message || 'Video upload failed', 'error');
    } finally {
      setUploadingVideo(false);
    }
  };

  const runScail2 = async () => {
    if (!canRun) return;
    sessionRef.current = [];
    prevVideoCountRef.current = lastOutputVideos?.length ?? 0;
    setIsGenerating(true);

    fetch(`${BACKEND_API.BASE_URL}/api/workflow/node-map/wan21-scail2`)
      .then((r) => r.json())
      .then((data) => { if (data.success) registerNodeMap(data.node_map); })
      .catch(() => {});

    try {
      const res = await fetch(`${BACKEND_API.BASE_URL}${BACKEND_API.ENDPOINTS.GENERATE}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          workflow_id: 'wan21-scail2',
          params: {
            image: referenceImageFile,
            reference_video: motionVideoFile,
            prompt: prompt.trim(),
            negative: negative.trim(),
            frame_length: frameLength,
            width,
            height,
            seed: seed === -1 ? Math.floor(Math.random() * 10_000_000_000) : seed,
            client_id: comfyService.clientId,
          },
        }),
      });
      const data = await res.json();
      if (!res.ok || !data.success) throw new Error(data.detail || 'SCAIL-2 failed');
      setPendingPromptId(String(data.prompt_id));
    } catch (err: any) {
      setIsGenerating(false);
      toast(err.message || 'SCAIL-2 failed', 'error');
    }
  };

  return (
    <WorkflowShell
      title="WAN 2.1 SCAIL-2"
      eyebrow="Motion transfer · GGUF"
      description="Animate a reference image using a pose/dance video. SCAIL-2 transfers the exact motion while preserving the subject's appearance."
      icon={Film}
      isGenerating={isGenerating}
      canGenerate={canRun}
      leftClassName="bg-[#050505]"
      hideOutputPane
      output={null}
    >
      <div className="mx-auto max-w-5xl space-y-4 px-4 pb-8">
        <VideoPreviewStrip
          currentVideo={currentVideo || history[0] || null}
          history={history}
          isGenerating={isGenerating}
          onSelectVideo={setCurrentVideo}
          downloadName="fedda-scail2.mp4"
        />

        <div className="grid gap-4 lg:grid-cols-[280px_1fr]">
          {/* Left: uploads */}
          <div className="space-y-4">
            <section className={panel}>
              <p className="mb-3 text-[10px] font-semibold uppercase tracking-[0.18em] text-zinc-600">
                Reference Image
              </p>
              <UploadDrop
                accept="image/*"
                label="Upload person photo"
                filename={referenceImageFile}
                busy={uploadingImage}
                onFile={handleImageUpload}
                preview={
                  refImagePreviewUrl ? (
                    <img
                      src={refImagePreviewUrl}
                      alt="Reference"
                      className="max-h-48 w-full rounded-lg object-contain"
                    />
                  ) : undefined
                }
              />
            </section>

            <section className={panel}>
              <p className="mb-3 text-[10px] font-semibold uppercase tracking-[0.18em] text-zinc-600">
                Motion Video
              </p>
              <UploadDrop
                accept="video/*"
                label="Upload pose/dance video"
                filename={motionVideoFile}
                busy={uploadingVideo}
                onFile={handleVideoUpload}
                preview={
                  motionPreviewUrl ? (
                    <video
                      src={motionPreviewUrl}
                      className="max-h-40 w-full rounded-lg object-contain"
                      muted
                      playsInline
                      controls
                    />
                  ) : undefined
                }
              />
            </section>
          </div>

          {/* Right: settings + generate */}
          <section className={panel}>
            <div className="space-y-4">
              <Field label="Positive prompt">
                <textarea
                  value={prompt}
                  onChange={(e) => setPrompt(e.target.value)}
                  rows={4}
                  className={classNames(inputBase, 'resize-y leading-relaxed')}
                  placeholder="a person dancing, cinematic lighting..."
                />
              </Field>

              <div>
                <button
                  type="button"
                  onClick={() => setShowNegative((v) => !v)}
                  className="text-[10px] font-semibold uppercase tracking-[0.16em] text-zinc-600 transition hover:text-zinc-400"
                >
                  {showNegative ? '− Negative prompt' : '+ Negative prompt (optional)'}
                </button>
                {showNegative && (
                  <textarea
                    value={negative}
                    onChange={(e) => setNegative(e.target.value)}
                    rows={2}
                    className={classNames(inputBase, 'mt-2 resize-y leading-relaxed')}
                    placeholder="blurry, distorted, low quality..."
                  />
                )}
              </div>

              <div className="grid gap-3 sm:grid-cols-2 md:grid-cols-4">
                <Field label="Frames">
                  <input
                    type="number"
                    min={8}
                    max={200}
                    step={1}
                    value={frameLength}
                    onChange={(e) => setFrameLength(Number(e.target.value))}
                    className={inputBase}
                  />
                </Field>
                <Field label="Width">
                  <input
                    type="number"
                    min={256}
                    step={16}
                    value={width}
                    onChange={(e) => setWidth(Number(e.target.value))}
                    className={inputBase}
                  />
                </Field>
                <Field label="Height">
                  <input
                    type="number"
                    min={256}
                    step={16}
                    value={height}
                    onChange={(e) => setHeight(Number(e.target.value))}
                    className={inputBase}
                  />
                </Field>
                <Field label="Seed (−1 = random)">
                  <input
                    type="number"
                    value={seed}
                    onChange={(e) => setSeed(Number(e.target.value))}
                    className={inputBase}
                  />
                </Field>
              </div>

              <div className="rounded-xl border border-white/10 bg-black/25 px-3 py-2 text-[11px] text-zinc-500">
                <span className="font-semibold text-zinc-400">Model:</span> SCAIL-2-Q4_K_M.gguf
                &nbsp;·&nbsp;
                <span className="font-semibold text-zinc-400">Output:</span> VIDEO/SCAIL2/
                &nbsp;·&nbsp;
                <span className="font-semibold text-zinc-400">Frames:</span> {frameLength} @ 24 fps
              </div>

              <NeutralButton
                onClick={runScail2}
                disabled={!canRun}
                className="w-full py-3 text-sm"
              >
                {isGenerating ? (
                  <Loader2 className="h-4 w-4 animate-spin" />
                ) : (
                  <Play className="h-4 w-4" />
                )}
                {isGenerating ? 'Generating SCAIL-2...' : 'Generate SCAIL-2'}
              </NeutralButton>

              {(!referenceImageFile || !motionVideoFile) && (
                <p className="text-center text-[11px] text-zinc-600">
                  Upload a reference image and motion video to enable generation
                </p>
              )}
            </div>
          </section>
        </div>
      </div>
    </WorkflowShell>
  );
}

export default Wan21Scail2Page;
