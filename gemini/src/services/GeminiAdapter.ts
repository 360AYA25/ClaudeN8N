import { GoogleGenerativeAI } from "@google/generative-ai";
import dotenv from 'dotenv';

dotenv.config();

export class GeminiAdapter {
  private genAI: GoogleGenerativeAI;
  private model: any;

  constructor(apiKey?: string) {
    const key = apiKey || process.env.GEMINI_API_KEY;
    if (!key) {
      console.warn("⚠️ GEMINI_API_KEY not set! AI features will fail.");
      this.genAI = new GoogleGenerativeAI("placeholder"); // Prevent crash on init
    } else {
      this.genAI = new GoogleGenerativeAI(key);
    }
    // Default to gemini-pro for agents
    this.model = this.genAI.getGenerativeModel({ model: "gemini-pro" });
  }

  /**
   * Generates a response from Gemini given a system prompt context and user task.
   */
  async generateResponse(systemPrompt: string, userTask: string, context: object): Promise<string> {
    if (!process.env.GEMINI_API_KEY) {
      return "MOCK RESPONSE: Gemini API Key missing. Please set GEMINI_API_KEY in .env";
    }

    // Construct a structured prompt that forces the model to act as an agent
    const prompt = `
${systemPrompt}

--- CURRENT EXECUTION STATE ---
${JSON.stringify(context, null, 2)}

--- YOUR TASK ---
${userTask}

IMPORTANT: Return ONLY the JSON or text as requested in the system prompt.
`;

    try {
      const result = await this.model.generateContent(prompt);
      const response = await result.response;
      return response.text();
    } catch (error) {
      console.error("[GeminiAdapter] Error:", error);
      throw new Error("Gemini generation failed");
    }
  }
}
