package ca.bc.gov.showcase.java.web;

import java.io.IOException;
import java.io.PrintWriter;
import java.lang.invoke.MethodHandles;
import java.util.Arrays;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.event.Level;

/**
 * Servlet implementation class Logging
 */
public class Logging extends HttpServlet {
	final static Logger logger = LoggerFactory.getLogger(MethodHandles.lookup().lookupClass());
	final static String LEVEL_DEBUG = Level.DEBUG.name();
	final static List<String> LEVELS = Arrays.asList("debug", "info", "warn", "error", "fatal");
	private static final long serialVersionUID = 1L;

	/**
	 * @see HttpServlet#HttpServlet()
	 */
	public Logging() {
		super();
	}

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse
	 *      response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		if ("submit".equalsIgnoreCase(request.getParameter("action"))) {
			Level level = Level.valueOf(request.getParameter("level"));
			String message = request.getParameter("message");
			switch (level) {
			case TRACE:
				logger.trace(message);
				break;
			case DEBUG:
				logger.debug(message);
				break;
			case INFO:
				logger.info(message);
				break;
			case WARN:
				logger.warn(message);
				break;
			case ERROR:
				logger.error(message);
				break;
			default:
				break;
			}
			this.log("Hello!");
		}
		PrintWriter writer = response.getWriter();
		response.setContentType("text/html");
		writer.append("<html>").append('\n');
		writer.append("<body>").append('\n');
		InfoServlet.write(request, writer);
		writer.append("<form>").append('\n');
		writer.append("<input type=\"text\" name=\"message\" value=\"Hello!\">").append('\n');
		writer.append("<select name=\"level\">").append('\n');
		for (Level level : Level.values()) {
			writer.append("<option value=\""+level.name()+"\">"+level.toString()+"</option>").append('\n');
		}
		writer.append("<input type=\"submit\" name=\"action\" value=\"submit\">").append('\n');
		writer.append("<input type=\"reset\" value=\"Reset\" />").append('\n');
		writer.append("</select>").append('\n');
		writer.append("</form>").append('\n');
		writer.append("</body>").append('\n');
		writer.append("</html>").append('\n');
	}

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse
	 *      response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		doGet(request, response);
	}

}
