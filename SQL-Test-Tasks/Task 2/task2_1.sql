SELECT	d_out.Number, d_out.Serial, core.Date, t_out.Sum, t_out.Type, core.Date2

FROM	lore.dbo.Transactions t_out,
		lore.dbo.Documents d_out,
		(
			SELECT doc_in.ClientId, doc_in.Date, doc_in.Type, max(t_in.Date) AS Date2
			FROM lore.dbo.Transactions t_in,	 
			(
				SELECT ClientId, Type, max(Date) AS Date
				FROM lore.dbo.Documents
				WHERE Type = 'P'
				GROUP BY ClientId, Type
			) doc_in
			WHERE t_in.ClientId = doc_in.ClientId
			GROUP BY doc_in.ClientId, doc_in.Date, doc_in.Type
		) core
		
WHERE	t_out.Date = core.Date2			and
		d_out.Date = core.Date			and
		t_out.ClientId = core.ClientId	and
		d_out.ClientId = core.ClientId	and
		d_out.Type = core.Type