export default function Modal({ modal, onClose }) {
  if (!modal) return null

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-box" onClick={e => e.stopPropagation()}>
        {modal.title && (
          <h3 style={{ fontSize: 17, fontWeight: 800, marginBottom: 8 }}>{modal.title}</h3>
        )}
        <p style={{ fontSize: 14, color: 'var(--muted)', lineHeight: 1.5, marginBottom: 20 }}>
          {modal.message}
        </p>
        <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end' }}>
          {modal.onCancel && (
            <button className="btn btn-ghost" onClick={() => { modal.onCancel(); onClose(); }}>
              {modal.cancelLabel || 'Cancel'}
            </button>
          )}
          <button
            className="btn btn-primary"
            style={modal.danger ? { background: '#f87171', color: '#fff' } : {}}
            onClick={() => { modal.onConfirm?.(); onClose(); }}
          >
            {modal.confirmLabel || 'OK'}
          </button>
        </div>
      </div>
    </div>
  )
}
