package com.livomobile;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.net.URL;

import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.appengine.api.urlfetch.HTTPRequest;
import com.google.appengine.api.urlfetch.HTTPResponse;
import com.google.appengine.api.urlfetch.URLFetchService;
import com.google.appengine.api.urlfetch.URLFetchServiceFactory;

public class DocumentationServlet extends HttpServlet {

	private static final URLFetchService FETCH_SERVICE = URLFetchServiceFactory
			.getURLFetchService();

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {
		
		Reader reader = new InputStreamReader(this.getClass().getResourceAsStream("documentation.html"));
		
		int next;
		while ((next = reader.read()) != -1) {
			
			resp.getOutputStream().write(next);
		}
		
		reader.close();
		resp.getOutputStream().close();
	}

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {

		HTTPResponse response = FETCH_SERVICE.fetch(new URL("https://livodoc.wordpress.com/"));
		
		resp.getOutputStream().write(response.getContent());
		resp.setStatus(response.getResponseCode());
		resp.getOutputStream().close();
	}
}
