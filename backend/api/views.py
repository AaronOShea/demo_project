from django.shortcuts import render

# Create your views here.
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from openai import OpenAI
from openai import APIError, AuthenticationError, RateLimitError
from django.conf import settings
import logging

logger = logging.getLogger(__name__)

# Lazy initialization of OpenAI client
_client = None

def get_openai_client():
    """Get or create OpenAI client instance."""
    global _client
    if _client is None:
        api_key = settings.OPENAI_API_KEY
        if not api_key:
            raise ValueError("OPENAI_API_KEY is not set in settings")
        _client = OpenAI(api_key=api_key)
    return _client

def _build_system_prompt(user_context):
    """Build system prompt including user's income, expenses, budget and goals when provided."""
    base = (
        "You are a friendly financial coach helping the user manage their money. "
        "Give practical, personalised advice. Be concise and encouraging."
    )
    if not user_context:
        return base

    parts = [base, "\n\n**Current user data (use this to personalise your answers):**"]
    transaction_income = user_context.get("income_this_month") or 0
    expected_income = user_context.get("expected_monthly_income") or 0
    
    # Show income: prefer transaction income, fallback to expected monthly income
    if transaction_income > 0:
        parts.append(f"- Income this month (from transactions): {transaction_income:.2f}")
        if expected_income > 0 and expected_income != transaction_income:
            parts.append(f"- Expected monthly income: {expected_income:.2f}")
    elif expected_income > 0:
        parts.append(f"- Monthly income: {expected_income:.2f}")
    
    spent = user_context.get("spent_this_month")
    if spent is not None:
        parts.append(f"- Spent this month: {spent:.2f}")
    budget = user_context.get("monthly_budget")
    if budget is not None and budget > 0:
        parts.append(f"- Monthly budget: {budget:.2f}")
    remaining = user_context.get("remaining_this_month")
    if remaining is not None:
        parts.append(f"- Remaining this month: {remaining:.2f}")
    pct = user_context.get("spent_percentage_of_income")
    if pct is not None:
        parts.append(f"- Spent as % of income: {pct:.1f}%")

    by_cat = user_context.get("spent_by_category")
    if by_cat:
        cat_str = ", ".join(f"{k}: {v:.2f}" for k, v in by_cat.items())
        parts.append(f"- Spending by category: {cat_str}")

    limits = user_context.get("category_limits")
    if limits:
        limits_str = ", ".join(f"{k}: {v:.2f}" for k, v in limits.items())
        parts.append(f"- Category limits (budgets): {limits_str}")

    recent = user_context.get("recent_expenses")
    if recent:
        lines = []
        for r in recent[:5]:
            line = f"  {r.get('category', '?')}: {r.get('amount', 0):.2f} ({r.get('date', '')})"
            if r.get("note"):
                line += f" — {r['note']}"
            lines.append(line)
        parts.append("- Recent expenses:\n" + "\n".join(lines))

    parts.append("\nRefer to their numbers when relevant and suggest concrete next steps.")
    return "\n".join(parts)


@api_view(["POST"])
def ai_chat(request):
    try:
        user_message = request.data.get("message", "")
        user_context = request.data.get("user_context")

        if not user_message:
            return Response(
                {"error": "Message is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not settings.OPENAI_API_KEY:
            logger.error("OPENAI_API_KEY is not set")
            return Response(
                {"error": "AI service is not configured"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        system_prompt = _build_system_prompt(user_context)
        client = get_openai_client()
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message}
            ],
        )

        reply = response.choices[0].message.content
        return Response({
            "reply": reply
        })
    
    except Exception as e:
        logger.error(f"Error in ai_chat: {str(e)}")
        return Response(
            {"error": "An error occurred while processing your request"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )