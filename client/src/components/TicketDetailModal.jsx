import React, { useState } from 'react';
import API from '../services/api';

export default function TicketDetailModal({ ticket, onClose, onRefresh }) {
  const [status, setStatus] = useState(ticket?.status || 'Submitted');
  const [priority, setPriority] = useState(ticket?.priority || 'Medium');
  const [commentText, setCommentText] = useState('');
  const [comments, setComments] = useState(ticket?.comments || []);

  const handleUpdate = async (e) => {
    e.preventDefault();
    try {
      await API.put(`/tickets/${ticket._id}`, { status, priority });
      onRefresh();
      onClose();
    } catch (error) {
      alert(error.response?.data?.message || 'Update failed');
    }
  };

  const handleAddComment = async (e) => {
    e.preventDefault();
    if (!commentText.trim()) return;
    try {
      const { data } = await API.post(`/tickets/${ticket._id}/comments`, { text: commentText });
      setComments(data.comments);
      setCommentText('');
    } catch (error) {
      alert(error.response?.data?.message || 'Failed to add comment');
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto p-6">
        <div className="flex justify-between items-start border-b pb-4 mb-4">
          <div>
            <span className="text-xs bg-indigo-50 text-indigo-600 px-3 py-1 rounded-full font-semibold">{ticket.category}</span>
            <h2 className="text-xl font-bold text-gray-900 mt-2">{ticket.title}</h2>
            <p className="text-xs text-gray-500">Location: {ticket.location}</p>
          </div>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 font-bold text-lg">✕</button>
        </div>

        <div className="space-y-4 mb-6">
          <div>
            <h4 className="text-xs font-semibold uppercase text-gray-400 mb-1">Description</h4>
            <p className="text-gray-700 bg-gray-50 p-3 rounded-lg">{ticket.description}</p>
          </div>

          <div className="bg-indigo-50/50 border border-indigo-100 p-4 rounded-xl">
            <h4 className="text-xs font-bold uppercase text-indigo-600 mb-1">CampusFlow AI Analysis & Triaging</h4>
            <p className="text-sm text-indigo-900">{ticket.aiAnalysis?.summary || 'AI analysis pending.'}</p>
            <div className="mt-2 flex space-x-4 text-xs font-semibold text-indigo-700">
              <span>Urgency Score: {ticket.aiAnalysis?.urgencyScore}/10</span>
              <span>Sentiment: {ticket.aiAnalysis?.sentiment}</span>
            </div>
          </div>

          {ticket.imageUrl && (
            <div>
              <h4 className="text-xs font-semibold uppercase text-gray-400 mb-1">Attached Image</h4>
              <img src={`http://localhost:5000${ticket.imageUrl}`} alt="Issue attachment" className="rounded-lg max-h-48 object-cover border" />
            </div>
          )}

          <form onSubmit={handleUpdate} className="grid grid-cols-2 gap-4 bg-gray-50 p-4 rounded-xl">
            <div>
              <label className="block text-xs font-semibold uppercase text-gray-500 mb-1">Status</label>
              <select value={status} onChange={(e) => setStatus(e.target.value)} className="w-full p-2 border rounded-lg text-sm bg-white">
                <option value="Submitted">Submitted</option>
                <option value="AI Triaged">AI Triaged</option>
                <option value="In Progress">In Progress</option>
                <option value="Resolved">Resolved</option>
                <option value="Closed">Closed</option>
              </select>
            </div>
            <div>
              <label className="block text-xs font-semibold uppercase text-gray-500 mb-1">Priority</label>
              <select value={priority} onChange={(e) => setPriority(e.target.value)} className="w-full p-2 border rounded-lg text-sm bg-white">
                <option value="Low">Low</option>
                <option value="Medium">Medium</option>
                <option value="High">High</option>
                <option value="Urgent">Urgent</option>
              </select>
            </div>
            <div className="col-span-2 flex justify-end">
              <button type="submit" className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-sm font-semibold shadow">
                Save Changes
              </button>
            </div>
          </form>

          <div className="border-t pt-4">
            <h4 className="text-xs font-bold uppercase text-gray-500 mb-3">Discussion & Updates</h4>
            <div className="space-y-3 max-h-40 overflow-y-auto mb-3">
              {comments.map((c, i) => (
                <div key={i} className="bg-gray-50 p-3 rounded-lg text-sm">
                  <div className="flex justify-between text-xs text-gray-400 mb-1">
                    <span className="font-semibold text-gray-700">{c.user?.name || 'User'}</span>
                    <span>{new Date(c.createdAt).toLocaleTimeString()}</span>
                  </div>
                  <p className="text-gray-700">{c.text}</p>
                </div>
              ))}
            </div>
            <form onSubmit={handleAddComment} className="flex space-x-2">
              <input
                type="text"
                placeholder="Add a comment or update..."
                value={commentText}
                onChange={(e) => setCommentText(e.target.value)}
                className="flex-1 p-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
              <button type="submit" className="px-4 py-2 bg-gray-900 hover:bg-black text-white rounded-lg text-sm font-semibold">
                Send
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
}
