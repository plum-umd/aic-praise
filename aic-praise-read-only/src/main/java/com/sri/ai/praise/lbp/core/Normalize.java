/*
 * Copyright (c) 2013, SRI International
 * All rights reserved.
 * Licensed under the The BSD 3-Clause License;
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at:
 * 
 * http://opensource.org/licenses/BSD-3-Clause
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the aic-praise nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */
package com.sri.ai.praise.lbp.core;


import com.google.common.annotations.Beta;
import com.sri.ai.expresso.api.Expression;
import com.sri.ai.grinder.api.Rewriter;
import com.sri.ai.grinder.api.RewritingProcess;
import com.sri.ai.praise.BreakConditionsContainingBothLogicalAndRandomVariablesHierarchical;
import com.sri.ai.praise.MoveAllRandomVariableValueExpressionConditionsDownHierarchical;
import com.sri.ai.praise.lbp.LBPRewriter;

/**
 * @see LBPRewriter#R_normalize
 * 
 * @author braz
 *
 */
@Beta
public class Normalize extends com.sri.ai.grinder.library.equality.cardinality.direct.core.Normalize implements LBPRewriter {

	public Normalize() {
		super();
		preSimplify  = new Simplify();
		postSimplify = new Simplify();
	}
	
	@Override
	public String getName() {
		return LBPRewriter.R_normalize;
	}
	
	protected Rewriter breakConditionsContainingBothLogicalAndRandomVariablesHierarchical = new BreakConditionsContainingBothLogicalAndRandomVariablesHierarchical();
	protected Rewriter moveAllRandomVariableValueExpressionConditionsDownHierarchical = new MoveAllRandomVariableValueExpressionConditionsDownHierarchical();
	
	@Override
	public Expression rewriteAfterBookkeeping(Expression expression, RewritingProcess process) {
		// Note that the order used below is far from arbitrary.
		// MoveAllRandomVariableValueExpressionConditionsDownHierarchical requires
		// its input to have already all conditional expressions on top, which is enforced by
		// IfThenElseExternalizationHierarchical.
		expression = preSimplify.rewrite(expression, process); // this first pass rewrites prod({{ <message value> | C }}) into exponentiated message values through lifting, rending a basic expression
		// it should be replaced by a normalizer with the single goal of lifting such expressions
		expression = breakConditionsContainingBothLogicalAndRandomVariablesHierarchical.rewrite(expression, process);
		expression = ifThenElseExternalizationHierarchical.rewrite(expression, process);
		expression = moveAllRandomVariableValueExpressionConditionsDownHierarchical.rewrite(expression, process);
		expression = postSimplify.rewrite(expression, process);
		return expression;
	}
}
